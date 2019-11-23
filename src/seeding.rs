//! Functions for loading book data.

use chrono::NaiveDateTime;
use diesel::pg::PgConnection;
use diesel::prelude::*;
use std::collections::HashMap;

use crate::schema::{
    lifepath_settings, skill_forks, skill_roots, skill_types, skills, stocks, traits, Book, Stat,
    ToolRequirement, TraitType,
};

mod deserialize;
use deserialize::*;

type StdError = Box<dyn std::error::Error>;
type StdResult<T> = Result<T, StdError>;

/// This is the function for loading all RON files in both dev and prod.
/// It relies on migrations have been run.
pub fn seed_book_data(db: &PgConnection) -> StdResult<()> {
    db.transaction(|| {
        seed_stocks(db)?;
        seed_dwarf_settings(db)?;
        seed_skills(db)?;
        seed_traits(db)?;

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

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "traits"]
struct NewTrait {
    book: Book,
    page: Option<i32>,
    name: String,
    cost: Option<i32>,
    typ: TraitType,
}

fn seed_stocks(db: &PgConnection) -> StdResult<()> {
    let new_stock = |stock: Stock| NewStock {
        book: Book::GoldRevised,
        name: stock.name,
        page: stock.page,
    };

    let stocks: Vec<_> = read_stocks()?.into_iter().map(new_stock).collect();

    diesel::insert_into(stocks::table)
        .values(stocks)
        .execute(db)?;

    Ok(())
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

#[derive(Queryable, Insertable, Debug, PartialEq, Eq)]
#[table_name = "skills"]
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

pub fn seed_dwarf_settings(db: &PgConnection) -> StdResult<()> {
    let stock_id = stocks::table
        .select(stocks::id)
        .filter(&stocks::name.eq("dwarves"))
        .first(db)?;

    let new_setting = |setting: Setting| NewSetting {
        stock_id,
        book: Book::GoldRevised,
        page: setting.page.into(),
        name: setting.name,
    };

    let settings: Vec<_> = read_dwarf_settings()?
        .into_iter()
        .map(new_setting)
        .collect();

    diesel::insert_into(lifepath_settings::table)
        .values(settings)
        .execute(db)?;

    Ok(())
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "stocks"]
pub struct NewStock {
    name: String,
    book: Book,
    page: i32,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "lifepath_settings"]
pub struct NewSetting {
    book: Book,
    page: i32,
    stock_id: i32,
    name: String,
}
