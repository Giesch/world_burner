//! Functions for loading book data.

use crate::repos::lifepaths::ReqPredicate;
use crate::schema::*;
use diesel::pg::PgConnection;
use diesel::prelude::*;
use std::collections::HashMap;
use std::convert::TryInto;

mod deserialize;
use deserialize::*;
mod insertable;
use insertable::*;

type StdError = Box<dyn std::error::Error>;
type StdResult<T> = Result<T, StdError>;

const BWGR: &str = "BWGR";

/// Loads all RON files into postgres.
/// Relies on migrations have been run, and makes assumptions about the book data.
/// Should not be used for user input.
pub fn seed_book_data(db: &PgConnection) -> StdResult<()> {
    db.transaction(|| {
        let gold_id = books::table
            .select(books::id)
            .filter(books::abbrev.eq(BWGR))
            .first(db)?;

        let skill_ids = seed_skills(db, gold_id)?;
        let trait_ids = seed_traits(db, gold_id)?;

        let stocks = seed_stocks(db, gold_id)?;
        seed_settings(db, &stocks, &skill_ids, &trait_ids, gold_id)?;

        clean_lifepath_names(db)?;

        Ok(())
    })
}

fn seed_traits(db: &PgConnection, book_id: i32) -> StdResult<HashMap<String, i32>> {
    let new_trait = |tr: Trait| NewTrait {
        book_id,
        page: tr.page(),
        name: tr.name(),
        cost: tr.cost(),
        taip: tr.trait_type(),
    };

    let new_traits: Vec<_> = read_traits()?.into_iter().map(new_trait).collect();

    let trait_ids = diesel::insert_into(traits::table)
        .values(new_traits)
        .returning((traits::name, traits::id))
        .get_results::<(String, i32)>(db)?
        .into_iter()
        .collect();

    Ok(trait_ids)
}

struct CreatedStock {
    pub id: i32,
    pub singular: String,
}

fn seed_stocks(db: &PgConnection, book_id: i32) -> StdResult<Vec<CreatedStock>> {
    let gold_stock = |stock: Stock| NewStock {
        book_id,
        name: stock.name,
        singular: stock.singular,
        page: stock.page,
    };

    let stocks: Vec<_> = read_stocks()?.into_iter().map(gold_stock).collect();

    let stocks: Vec<_> = diesel::insert_into(stocks::table)
        .values(stocks)
        .returning((stocks::id, stocks::singular))
        .get_results::<(i32, String)>(db)?
        .into_iter()
        .map(|(id, singular)| CreatedStock { id, singular })
        .collect();

    Ok(stocks)
}

fn seed_skills(db: &PgConnection, book_id: i32) -> StdResult<HashMap<String, i32>> {
    let config_skills = read_skills()?;

    let mut new_skills = Vec::new();
    for skill in &config_skills {
        let new_skill = NewSkill {
            book_id,
            name: skill.name.clone(),
            page: skill.page,
            tools: skill.tools,
            tools_expendable: skill.tools_expendable,
            magical: skill.magical,
            wise: skill.name.ends_with("-wise") || skill.name == "wises",
            training: skill.training,
        };

        new_skills.push(new_skill);
    }

    let skill_ids: HashMap<String, i32> = diesel::insert_into(skills::table)
        .values(new_skills)
        .returning((skills::name, skills::id))
        .get_results(db)?
        .into_iter()
        .collect();

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

    Ok(skill_ids)
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
    skill_ids: &HashMap<String, i32>,
    trait_ids: &HashMap<String, i32>,
    book_id: i32,
) -> StdResult<()> {
    let mut settings_by_stock_id = HashMap::new();
    for stock in stocks {
        let stock_settings = read_stock_settings("gold_revised", &stock.singular)?;
        settings_by_stock_id.insert(stock.id, stock_settings);
    }

    let all_settings: Vec<_> = settings_by_stock_id.values().flatten().collect();

    let all_lifepaths: Vec<_> = settings_by_stock_id
        .values()
        .flatten()
        .flat_map(|setting| &setting.lifepaths)
        .collect();

    // settings

    let new_settings = new_settings(&settings_by_stock_id, book_id)?;

    let setting_ids: HashMap<_, _> = diesel::insert_into(lifepath_settings::table)
        .values(new_settings)
        .returning((lifepath_settings::name, lifepath_settings::id))
        .get_results::<(String, i32)>(db)?
        .into_iter()
        .collect();

    // lifepaths

    let new_lifepaths = new_lifepaths(&all_settings, &setting_ids, book_id)?;

    let lifepath_ids: HashMap<_, _> = diesel::insert_into(lifepaths::table)
        .values(new_lifepaths)
        .returning((lifepaths::name, lifepaths::id))
        .get_results::<(String, i32)>(db)?
        .into_iter()
        .collect();

    // requirements

    let new_requirements = new_requirements(&all_lifepaths, &lifepath_ids, &setting_ids)?;

    diesel::insert_into(lifepath_reqs::table)
        .values(new_requirements)
        .execute(db)?;

    // leads

    let new_leads = new_leads(&all_lifepaths, &lifepath_ids, &setting_ids)?;

    diesel::insert_into(leads::table)
        .values(new_leads)
        .execute(db)?;

    // skill lists

    let new_skill_lists = new_skill_lists(&all_lifepaths, &lifepath_ids, &skill_ids)?;

    diesel::insert_into(lifepath_skill_lists::table)
        .values(new_skill_lists)
        .execute(db)?;

    // trait lists

    let new_trait_lists = new_trait_lists(&all_lifepaths, &lifepath_ids, &trait_ids)?;

    diesel::insert_into(lifepath_trait_lists::table)
        .values(new_trait_lists)
        .execute(db)?;

    Ok(())
}

fn new_requirements(
    all_lifepaths: &[&deserialize::Lifepath],
    lifepath_ids: &HashMap<String, i32>,
    setting_ids: &HashMap<String, i32>,
) -> StdResult<Vec<NewRequirement>> {
    let mut new_requirements = Vec::new();

    for lifepath in all_lifepaths {
        if let Some(Requirement { req, desc }) = &lifepath.requires {
            let &lifepath_id = lifepath_ids
                .get(&lifepath.name)
                .ok_or_else(|| format!("missing lifepath id for {:#?}", lifepath))?;

            let predicate = convert_req(req, lifepath_ids, setting_ids)?;
            let predicate = serde_json::to_value(predicate)?;

            let new_req = NewRequirement {
                lifepath_id,
                predicate,
                description: desc.clone(),
            };
            new_requirements.push(new_req);
        }
    }

    Ok(new_requirements)
}

fn convert_req(
    req: &deserialize::LifepathReq,
    lifepath_ids: &HashMap<String, i32>,
    setting_ids: &HashMap<String, i32>,
) -> StdResult<ReqPredicate> {
    use deserialize::LifepathReq as Req;

    let requirement = match req {
        Req::LP(name, count) => {
            let &lifepath_id = lifepath_ids
                .get(name)
                .ok_or_else(|| format!("missing lifepath id for {:#?}", name))?;
            let count = *count;

            ReqPredicate::Lifepath { lifepath_id, count }
        }

        Req::PreviousLifepaths(count) => ReqPredicate::PreviousLifepaths { count: *count },

        Req::Setting(count, name) => {
            let &setting_id = setting_ids
                .get(name)
                .ok_or_else(|| format!("missing setting id for {:#?}", name))?;
            let count = *count;

            ReqPredicate::Setting { setting_id, count }
        }

        Req::Any(sub_reqs) => {
            let sub_reqs: StdResult<Vec<_>> = sub_reqs
                .iter()
                .map(|req| convert_req(req, lifepath_ids, setting_ids))
                .collect();

            ReqPredicate::Any(sub_reqs?)
        }

        Req::All(sub_reqs) => {
            let sub_reqs: StdResult<Vec<_>> = sub_reqs
                .iter()
                .map(|req| convert_req(req, lifepath_ids, setting_ids))
                .collect();

            ReqPredicate::All(sub_reqs?)
        }
    };

    Ok(requirement)
}

fn new_leads(
    all_lifepaths: &[&deserialize::Lifepath],
    lifepath_ids: &HashMap<String, i32>,
    setting_ids: &HashMap<String, i32>,
) -> StdResult<Vec<NewLead>> {
    let mut new_leads = Vec::new();
    for lifepath in all_lifepaths {
        let &lifepath_id = lifepath_ids
            .get(&lifepath.name)
            .ok_or_else(|| format!("missing lifepath id for {:#?}", lifepath))?;
        for lead in &lifepath.leads {
            let &setting_id = setting_ids
                .get(lead)
                .ok_or_else(|| format!("missing setting id for {:#?}", lead))?;

            let new_lead = NewLead {
                lifepath_id,
                setting_id,
            };

            new_leads.push(new_lead);
        }
    }

    Ok(new_leads)
}

fn new_trait_lists(
    all_lifepaths: &[&deserialize::Lifepath],
    lifepath_ids: &HashMap<String, i32>,
    trait_ids: &HashMap<String, i32>,
) -> StdResult<Vec<NewTraitList>> {
    let mut new_trait_lists = Vec::new();

    for lifepath in all_lifepaths {
        let &lifepath_id = lifepath_ids
            .get(&lifepath.name)
            .ok_or_else(|| format!("missing lifepath: {}", lifepath.name))?;
        for (i, trait_name) in lifepath.traits.iter().enumerate() {
            let (trait_id, char_trait) = if let Some(id) = trait_ids.get(trait_name) {
                (Some(*id), None)
            } else {
                (None, Some(trait_name.to_string()))
            };

            let trait_list = NewTraitList {
                list_position: i.try_into()?,
                lifepath_id,
                trait_id,
                char_trait,
            };

            new_trait_lists.push(trait_list);
        }
    }

    Ok(new_trait_lists)
}

fn new_skill_lists(
    all_lifepaths: &[&deserialize::Lifepath],
    lifepath_ids: &HashMap<String, i32>,
    skill_ids: &HashMap<String, i32>,
) -> StdResult<Vec<NewSkillList>> {
    let mut new_skill_lists = Vec::new();

    for lifepath in all_lifepaths {
        let &lifepath_id = lifepath_ids
            .get(&lifepath.name)
            .ok_or_else(|| format!("missing lifepath: {}", lifepath.name))?;

        for (i, skill_name) in lifepath.skills.iter().enumerate() {
            let (skill_id, entryless_skill) = id_and_entryless_name(skill_ids, skill_name)?;

            let new_skill_list = NewSkillList {
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
    skill_ids: &HashMap<String, i32>,
    skill_name: &str,
) -> StdResult<(i32, Option<String>)> {
    if let Some(skill_id) = skill_ids.get(skill_name) {
        return Ok((*skill_id, None));
    }

    if skill_name.ends_with("-wise") {
        let wises_id = skill_ids.get("wises").ok_or("wises skill missing")?;
        return Ok((*wises_id, Some(skill_name.to_string())));
    }

    if skill_name.ends_with("history") {
        let history_id = skill_ids.get("history").ok_or("history skill missing")?;
        return Ok((*history_id, Some(skill_name.to_string())));
    }

    Err(format!("entryless non-knowledge skill: {}", skill_name).into())
}

fn new_settings(
    settings_by_stock_id: &HashMap<i32, Vec<LifepathSetting>>,
    book_id: i32,
) -> StdResult<Vec<NewSetting>> {
    let mut new_settings = Vec::new();

    for (&stock_id, stock_settings) in settings_by_stock_id.iter() {
        let new_setting = |setting: &deserialize::LifepathSetting| NewSetting {
            book_id,
            stock_id,
            page: setting.page,
            name: setting.name.clone(),
        };

        new_settings.extend(stock_settings.iter().map(new_setting))
    }

    Ok(new_settings)
}

fn new_lifepaths(
    all_settings: &[&LifepathSetting],
    setting_ids: &HashMap<String, i32>,
    book_id: i32,
) -> StdResult<Vec<NewLifepath>> {
    let mut new_lifepaths = Vec::new();

    for setting in all_settings {
        let &lifepath_setting_id = setting_ids
            .get(&setting.name)
            .ok_or_else(|| format!("uncreated setting: {}", setting.name))?;

        for lifepath in &setting.lifepaths {
            let new_lifepath = new_lifepath(lifepath, lifepath_setting_id, book_id)?;
            new_lifepaths.push(new_lifepath);
        }
    }

    Ok(new_lifepaths)
}

fn new_lifepath(
    lifepath: &deserialize::Lifepath,
    lifepath_setting_id: i32,
    book_id: i32,
) -> StdResult<NewLifepath> {
    let (years_min, years_max) = if lifepath.years.is_some() {
        (None, None)
    } else {
        match lifepath.name.as_str() {
            "advisor to the court" => (Some(1), Some(3)),
            "prince of the blood" => (Some(2), Some(20)),
            _ => return Err(format!("invalid lifepath years: {:#?}", lifepath).into()),
        }
    };

    let (res, res_calc) = if let Some(r) = lifepath.res {
        (Some(r), None)
    } else {
        match lifepath.name.as_str() {
            "advisor to the court" => (None, Some(ResCalc::TenPerYear)),
            "hostage" => (None, Some(ResCalc::HalfPrevious)),
            _ => return Err(format!("invalid lifepath resources: {:#?}", lifepath).into()),
        }
    };

    Ok(NewLifepath {
        book_id,
        lifepath_setting_id,
        page: lifepath.page,
        name: lifepath.name.clone(),
        born: lifepath.born,

        years: lifepath.years,
        years_min,
        years_max,

        gen_skill_pts: lifepath.gen_skill_pts,
        skill_pts: lifepath.skill_pts,
        trait_pts: lifepath.trait_pts,

        stat_mod: lifepath.stat_mod.stat_mod_type(),
        stat_mod_val: lifepath.stat_mod.stat_mod_val(),

        res,
        res_calc,
    })
}

/// Removes parenthesized setting names from lifepath names
/// The setting names are neccessary to disambiguate lifepaths during seeding,
/// but unnecessary noise afterwards.
fn clean_lifepath_names(db: &PgConnection) -> StdResult<()> {
    let to_clean: Vec<LifepathName> = lifepaths::table
        .select((lifepaths::id, lifepaths::name))
        .filter(lifepaths::name.ilike("%(%"))
        .load(db)?;

    for LifepathName { id, name } in to_clean {
        let mut words: Vec<_> = name.split(' ').collect();
        words.pop();
        let cleaned = words.join(" ");

        diesel::update(lifepaths::table.filter(lifepaths::id.eq(id)))
            .set(lifepaths::name.eq(cleaned))
            .execute(db)?;
    }

    Ok(())
}

#[derive(Queryable, Debug)]
struct LifepathName {
    id: i32,
    name: String,
}
