//! Functions for loading book data.

use diesel::pg::PgConnection;
use diesel::prelude::*;
use std::collections::HashMap;
use std::convert::TryInto;

use crate::schema::*;

mod deserialize;
use deserialize::*;

mod insertable;
use insertable::*;

mod queryable;
use queryable::*;

type StdError = Box<dyn std::error::Error>;
type StdResult<T> = Result<T, StdError>;

const HALF_PREVIOUS: &str = "half_previous";

const PRINCE_YEARS_MIN: i32 = 2;
const PRINCE_YEARS_MAX: i32 = 20;

/// This is the function for loading all RON files in both dev and prod.
/// It relies on migrations have been run, and makes assumptions about the book data.
/// It should not be used for user input.
pub fn seed_book_data(db: &PgConnection) -> StdResult<()> {
    db.transaction(|| {
        let skills = seed_skills(db)?;
        seed_traits(db)?;

        let stocks = seed_stocks(db)?;
        seed_settings(db, &stocks, &skills)?;

        Ok(())
    })
}

fn seed_traits(db: &PgConnection) -> StdResult<()> {
    let new_trait = |tr: Trait| NewTrait {
        book: Book::GoldRevised,
        page: tr.page(),
        name: tr.name(),
        cost: tr.cost(),
        typ: tr.trait_type(),
    };

    let new_traits: Vec<_> = read_traits()?.into_iter().map(new_trait).collect();

    diesel::insert_into(traits::table)
        .values(new_traits)
        .execute(db)?;

    Ok(())
}

fn seed_stocks(db: &PgConnection) -> StdResult<Vec<CreatedStock>> {
    let gold_stock = |stock: Stock| NewStock {
        book: Book::GoldRevised,
        name: stock.name,
        singular: stock.singular,
        page: stock.page,
    };

    let stocks: Vec<_> = read_stocks()?.into_iter().map(gold_stock).collect();

    let stocks: Vec<_> = diesel::insert_into(stocks::table)
        .values(stocks)
        .get_results::<CreatedStock>(db)?;

    Ok(stocks)
}

fn seed_skills(db: &PgConnection) -> StdResult<Vec<CreatedSkill>> {
    let skill_type_ids: HashMap<String, i32> = skill_types::table
        .select((skill_types::id, skill_types::name))
        .load::<(i32, String)>(db)?
        .into_iter()
        .map(|(id, name)| (name, id))
        .collect();

    let config_skills = read_skills()?;

    let mut new_skills = Vec::new();
    for skill in &config_skills {
        let skill_type_id = *skill_type_ids
            .get(skill.skill_type.db_name())
            .ok_or_else(|| format!("unknown skill type: {:?}", skill.skill_type))?;

        let new_skill = NewSkill {
            name: skill.name.clone(),
            book: Book::GoldRevised,
            page: skill.page,
            tools: skill.tools,
            magical: skill.magical,
            wise: skill.name.ends_with("-wise"),
            skill_type_id,
        };

        new_skills.push(new_skill);
    }

    let created_skills: Vec<CreatedSkill> = diesel::insert_into(skills::table)
        .values(new_skills)
        .get_results(db)?;

    let mut skill_ids: HashMap<String, i32> = HashMap::new();
    for skill in &created_skills {
        skill_ids.insert(skill.name.clone(), skill.id);
    }

    let mut new_skill_roots = Vec::new();
    for skill in &config_skills {
        let skill_id = skill_ids
            .get(&skill.name)
            .ok_or_else(|| format!("unknown skill: {}", skill.name))?;
        let new_skill_root = new_skill_root(*skill_id, &skill.root);

        new_skill_roots.push(new_skill_root);
    }

    diesel::insert_into(skill_roots::table)
        .values(new_skill_roots)
        .execute(db)?;

    Ok(created_skills)
}

fn new_skill_root(skill_id: i32, root: &SkillRoot) -> NewSkillRoot {
    use SkillRoot::*;

    match root {
        Single(stat) => NewSkillRoot {
            skill_id,
            first_stat_root: Some(*stat),
            second_stat_root: None,
            attribute_root: None,
        },

        Pair(first, second) => NewSkillRoot {
            skill_id,
            first_stat_root: Some(*first),
            second_stat_root: Some(*second),
            attribute_root: None,
        },

        Attribute(attr) => NewSkillRoot {
            skill_id,
            first_stat_root: None,
            second_stat_root: None,
            attribute_root: Some(attr.to_string()),
        },
    }
}

fn seed_settings(
    db: &PgConnection,
    stocks: &[CreatedStock],
    skills: &[CreatedSkill],
) -> StdResult<()> {
    let mut settings_by_stock_id = HashMap::new();
    for stock in stocks {
        let stock_settings = read_stock_settings("gold_revised", &stock.singular)?;
        settings_by_stock_id.insert(stock.id, stock_settings);
    }

    let new_settings = new_settings(&settings_by_stock_id)?;

    let setting_ids_by_name: HashMap<_, _> = diesel::insert_into(lifepath_settings::table)
        .values(new_settings)
        .get_results::<CreatedSetting>(db)?
        .into_iter()
        .map(|setting| (setting.name, setting.id))
        .collect();

    let all_settings: Vec<_> = settings_by_stock_id.values().flatten().collect();
    let new_lifepaths = new_lifepaths(&all_settings, &setting_ids_by_name)?;

    let created_lifepaths = diesel::insert_into(lifepaths::table)
        .values(new_lifepaths)
        .get_results::<CreatedLifepath>(db)?;

    // skill lists

    let lifepath_ids_by_name: HashMap<_, _> = created_lifepaths
        .iter()
        .map(|lp| (lp.name.clone(), lp.id))
        .collect();

    let skills_by_name: HashMap<_, _> = skills
        .iter()
        .map(|skill| (skill.name.clone(), skill))
        .collect();

    let all_lifepaths: Vec<_> = settings_by_stock_id
        .values()
        .flatten()
        .flat_map(|setting| &setting.lifepaths)
        .collect();

    let new_lifepath_skill_lists =
        new_lifepath_skill_lists(&all_lifepaths, &lifepath_ids_by_name, &skills_by_name)?;

    diesel::insert_into(lifepath_skill_lists::table)
        .values(new_lifepath_skill_lists)
        .execute(db)?;

    Ok(())
}

fn new_lifepath_skill_lists(
    all_lifepaths: &[&deserialize::Lifepath],
    lifepath_ids_by_name: &HashMap<String, i32>,
    skills_by_name: &HashMap<String, &CreatedSkill>,
) -> StdResult<Vec<NewLifepathSkillList>> {
    let mut new_skill_lists = Vec::new();

    for lifepath in all_lifepaths {
        for (i, skill_name) in lifepath.skills.iter().enumerate() {
            let &lifepath_id = lifepath_ids_by_name
                .get(&lifepath.name)
                .ok_or_else(|| format!("missing lifepath: {}", lifepath.name))?;

            let (skill_id, entryless_skill) = id_and_entryless_name(skills_by_name, skill_name)?;

            let new_skill_list = NewLifepathSkillList {
                list_position: i.try_into()?,
                lifepath_id,
                skill_id,
                entryless_skill,
            };

            new_skill_lists.push(new_skill_list);
        }
    }

    Ok(new_skill_lists)
}

fn id_and_entryless_name(
    skills_by_name: &HashMap<String, &CreatedSkill>,
    skill_name: &str,
) -> StdResult<(i32, Option<String>)> {
    if let Some(skill) = skills_by_name.get(skill_name) {
        return Ok((skill.id, None));
    }

    if skill_name.ends_with("-wise") {
        let wises = skills_by_name.get("wises").ok_or("wises skill missing")?;
        return Ok((wises.id, Some(skill_name.to_string())));
    }

    if skill_name.ends_with("history") {
        let history = skills_by_name
            .get("history")
            .ok_or("history skill missing")?;
        return Ok((history.id, Some(skill_name.to_string())));
    }

    Err(format!("entryless non-knowledge skill: {}", skill_name).into())
}

fn new_settings(
    settings_by_stock_id: &HashMap<i32, Vec<LifepathSetting>>,
) -> StdResult<Vec<NewSetting>> {
    let mut new_settings = Vec::new();

    for (&stock_id, stock_settings) in settings_by_stock_id.iter() {
        let new_setting = |setting: &deserialize::LifepathSetting| NewSetting {
            stock_id,
            book: Book::GoldRevised,
            page: setting.page,
            name: setting.name.clone(),
        };

        new_settings.extend(stock_settings.iter().map(new_setting))
    }

    Ok(new_settings)
}

fn new_lifepaths(
    all_settings: &[&LifepathSetting],
    setting_ids_by_name: &HashMap<String, i32>,
) -> StdResult<Vec<NewLifepath>> {
    let mut new_lifepaths = Vec::new();

    for setting in all_settings {
        let &lifepath_setting_id = setting_ids_by_name
            .get(&setting.name)
            .ok_or_else(|| format!("uncreated setting: {}", setting.name))?;

        for lifepath in &setting.lifepaths {
            let new_lifepath = new_lifepath(lifepath, lifepath_setting_id);
            new_lifepaths.push(new_lifepath);
        }
    }

    Ok(new_lifepaths)
}

fn new_lifepath(lifepath: &deserialize::Lifepath, lifepath_setting_id: i32) -> NewLifepath {
    // prince of the blood
    let (years_min, years_max) = if lifepath.years.is_some() {
        (None, None)
    } else {
        (Some(PRINCE_YEARS_MIN), Some(PRINCE_YEARS_MAX))
    };

    // hostage
    let (res, res_calc) = if let Some(r) = lifepath.res {
        (Some(r), None)
    } else {
        (None, Some(HALF_PREVIOUS.to_string()))
    };

    NewLifepath {
        lifepath_setting_id,
        book: Book::GoldRevised,
        page: lifepath.page,
        name: lifepath.name.clone(),

        years: lifepath.years,
        years_min,
        years_max,

        gen_skill_pts: lifepath.general_skill_pts,
        skill_pts: lifepath.skill_pts,
        trait_pts: lifepath.trait_pts,

        stat_mod: lifepath.stat_mod.stat_mod_type(),
        stat_mod_val: lifepath.stat_mod.stat_mod_val(),

        res,
        res_calc,
    }
}
