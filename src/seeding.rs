//! Functions for loading book data.

use chrono::NaiveDateTime;
use diesel::pg::PgConnection;
use diesel::prelude::*;
use std::collections::HashMap;

use crate::schema;
use crate::schema::*;

mod deserialize;
use deserialize::*;

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
        seed_skills(db)?;
        seed_traits(db)?;

        let stocks = seed_stocks(db)?;
        seed_settings(db, &stocks)?;

        Ok(())
    })
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "lifepaths"]
struct NewLifepath {
    book: Book,
    lifepath_setting_id: i32,
    page: i32,
    name: String,

    years: Option<i32>,
    years_min: Option<i32>,
    years_max: Option<i32>,

    gen_skill_pts: i32,
    skill_pts: i32,
    trait_pts: i32,

    stat_mod: Option<schema::StatMod>,
    stat_mod_val: Option<i32>,

    res: Option<i32>,
    res_calc: Option<String>,
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

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "traits"]
struct NewTrait {
    book: Book,
    page: i32,
    name: String,
    cost: Option<i32>,
    typ: TraitType,
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

#[derive(Deserialize, Debug, PartialEq, Eq)]
struct SkillType {
    id: i32,
    name: String,
}

fn seed_skills(db: &PgConnection) -> StdResult<()> {
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

    let mut config_roots: HashMap<String, SkillRoot> = HashMap::new();
    for skill in &config_skills {
        config_roots.insert(skill.name.clone(), skill.root.clone());
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

    let mut new_forks = Vec::new();
    for skill in &config_skills {
        let &skill_id = skill_ids
            .get(&skill.name)
            .ok_or_else(|| format!("unknown skill: {}", skill.name))?;
        for fork in &skill.forks {
            if let Some(&fork_id) = skill_ids.get(fork) {
                let new_fork = NewSkillFork { skill_id, fork_id };
                new_forks.push(new_fork);
            }
        }
    }

    diesel::insert_into(skill_forks::table)
        .values(new_forks)
        .execute(db)?;

    Ok(())
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "skill_forks"]
struct NewSkillFork {
    skill_id: i32,
    fork_id: i32,
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

#[derive(Queryable, Debug, PartialEq, Eq)]
struct CreatedSkill {
    id: i32,
    skill_type_id: i32,
    book: Book,
    page: i32,
    name: String,
    magical: bool,
    wise: bool,
    tools: ToolRequirement,
    created_at: NaiveDateTime,
    updated_at: NaiveDateTime,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "skill_roots"]
struct NewSkillRoot {
    skill_id: i32,
    first_stat_root: Option<Stat>,
    second_stat_root: Option<Stat>,
    attribute_root: Option<String>,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "skills"]
struct NewSkill {
    name: String,
    book: Book,
    page: i32,
    magical: bool,
    tools: ToolRequirement,
    wise: bool,
    skill_type_id: i32,
}

fn seed_settings(db: &PgConnection, stocks: &[CreatedStock]) -> StdResult<()> {
    let mut settings_by_stock_id = HashMap::new();
    for stock in stocks {
        let stock_settings = read_stock_settings("gold_revised", &stock.singular)?;
        settings_by_stock_id.insert(stock.id, stock_settings);
    }

    let mut new_settings = Vec::new();
    for stock in stocks {
        let stock_settings = settings_by_stock_id
            .get(&stock.id)
            .ok_or_else(|| format!("unexpected stock: {} with id: {}", stock.name, stock.id))?;
        for setting in stock_settings {
            let new_setting = NewSetting {
                stock_id: stock.id,
                book: Book::GoldRevised,
                page: setting.page,
                name: setting.name.clone(),
            };

            new_settings.push(new_setting);
        }
    }

    let setting_ids_by_name: HashMap<String, i32> = diesel::insert_into(lifepath_settings::table)
        .values(new_settings)
        .get_results::<CreatedSetting>(db)?
        .into_iter()
        .map(|setting| (setting.name, setting.id))
        .collect();

    let mut new_lifepaths = Vec::new();
    for stock in stocks {
        let stock_settings = settings_by_stock_id
            .get(&stock.id)
            .ok_or_else(|| format!("unexpected stock: {} with id: {}", stock.name, stock.id))?;

        for setting in stock_settings {
            let &lifepath_setting_id = setting_ids_by_name
                .get(&setting.name)
                .ok_or_else(|| format!("unexpected setting: {}", setting.name))?;

            for lifepath in &setting.lifepaths {
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

                let new_lifepath = NewLifepath {
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
                };

                new_lifepaths.push(new_lifepath);
            }
        }
    }

    diesel::insert_into(lifepaths::table)
        .values(new_lifepaths)
        .execute(db)?;

    Ok(())
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "stocks"]
pub struct NewStock {
    name: String,
    book: Book,
    page: i32,
    singular: String,
}

#[derive(Queryable, Debug, PartialEq, Eq)]
pub struct CreatedStock {
    id: i32,
    book: Book,
    name: String,
    singular: String,
    page: i32,
    created_at: NaiveDateTime,
    updated_at: NaiveDateTime,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "lifepath_settings"]
pub struct NewSetting {
    book: Book,
    page: i32,
    stock_id: i32,
    name: String,
}

#[derive(Queryable, Debug, PartialEq, Eq)]
struct CreatedSetting {
    id: i32,
    book: Book,
    stock_id: i32,
    page: i32,
    name: String,
    created_at: NaiveDateTime,
    updated_at: NaiveDateTime,
}
