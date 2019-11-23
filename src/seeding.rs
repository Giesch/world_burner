//! Functions for loading book data.

use chrono::NaiveDateTime;
use diesel::pg::PgConnection;
use diesel::prelude::*;

use crate::schema::{
    lifepath_settings, skill_forks, skill_roots, skill_types, skills, stocks, Book, Stat,
    ToolRequirement,
};

mod deserialize;
use deserialize::*;

type StdResult<T> = Result<T, Box<dyn std::error::Error>>;

/// This is the function for loading all RON files in both dev and prod.
/// It expects that the environment variable DATABASE_URL is set,
/// and that migrations have been run.
pub fn seed_book_data(db: &PgConnection) -> StdResult<()> {
    seed_stocks(db)?;
    seed_dwarf_settings(db)?;
    seed_skills(db)?;

    Ok(())
}

fn seed_stocks(db: &PgConnection) -> StdResult<()> {
    let stocks: Vec<_> = read_stocks()?
        .into_iter()
        .map(|stock| NewStock {
            book: Book::GoldRevised,
            name: stock.name,
            page: stock.page,
        })
        .collect();

    diesel::insert_into(stocks::table)
        .values(stocks)
        .execute(db)?;

    Ok(())
}

use std::collections::HashMap;

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
            .ok_or("unknown skill type")?;

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

    let mut config_roots: HashMap<String, deserialize::SkillRoot> = HashMap::new();
    for skill in &config_skills {
        config_roots.insert(skill.name.clone(), skill.root);
    }

    let mut new_skill_roots = Vec::new();
    for skill in &config_skills {
        let skill_id = skill_ids
            .get(&skill.name)
            .ok_or(format!("unknown skill: {}", skill.name))?;
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
            .ok_or(format!("unknown skill: {}", skill.name))?;
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

// TODO do this in a less dumb way
// just use the final user representation of a root in the ron config
fn new_skill_root(skill_id: i32, root: &deserialize::SkillRoot) -> NewSkillRoot {
    use deserialize::SkillRoot::*;
    match root {
        Will => NewSkillRoot {
            skill_id,
            first_stat_root: Some(Stat::Will),
            second_stat_root: None,
            attribute_root: None,
        },
        Perception => NewSkillRoot {
            skill_id,
            first_stat_root: Some(Stat::Perception),
            second_stat_root: None,
            attribute_root: None,
        },
        Forte => NewSkillRoot {
            skill_id,
            first_stat_root: Some(Stat::Forte),
            second_stat_root: None,
            attribute_root: None,
        },
        Power => NewSkillRoot {
            skill_id,
            first_stat_root: Some(Stat::Power),
            second_stat_root: None,
            attribute_root: None,
        },
        Speed => NewSkillRoot {
            skill_id,
            first_stat_root: Some(Stat::Speed),
            second_stat_root: None,
            attribute_root: None,
        },
        Agility => NewSkillRoot {
            skill_id,
            first_stat_root: Some(Stat::Agility),
            second_stat_root: None,
            attribute_root: None,
        },
        WillPer => NewSkillRoot {
            skill_id,
            first_stat_root: Some(Stat::Will),
            second_stat_root: Some(Stat::Perception),
            attribute_root: None,
        },
        PerAgi => NewSkillRoot {
            skill_id,
            first_stat_root: Some(Stat::Perception),
            second_stat_root: Some(Stat::Agility),
            attribute_root: None,
        },
        PerPow => NewSkillRoot {
            skill_id,
            first_stat_root: Some(Stat::Perception),
            second_stat_root: Some(Stat::Power),
            attribute_root: None,
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

    let settings: Vec<_> = read_dwarf_settings()?
        .into_iter()
        .map(|setting| NewSetting {
            stock_id,
            book: Book::GoldRevised,
            page: setting.page.into(),
            name: setting.name,
        })
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
