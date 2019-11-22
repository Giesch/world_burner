//! Functions for loading book data.

use diesel::pg::PgConnection;
use diesel::prelude::*;

use crate::schema::{lifepath_settings, skill_types, skills, stocks, Book, ToolRequirement};

mod deserialize;
use deserialize::*;

type StdResult<T> = Result<T, Box<dyn std::error::Error>>;

/// This is the function for loading all RON files in both dev and prod.
/// It expects that the environment variable DATABASE_URL is set,
/// and that migrations have been run.
pub fn seed_book_data(db: &PgConnection) -> StdResult<()> {
    seed_stocks(db)?;
    seed_dwarf_settings(db)?;
    // seed_skills(db)?;

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

    let new_skill = |skill: &Skill| NewSkill {
        name: skill.name.clone(),
        page: skill.page,
        tools: skill.tools,
        magical: skill.magical,
        wise: skill.name.ends_with("-wise"),
        skill_type_id: *skill_type_ids
            .get(skill.skill_type.db_name())
            .expect("failed to find skill type id"),
    };

    let new_skills: Vec<_> = read_skills()?.iter().map(new_skill).collect();

    diesel::insert_into(skills::table)
        .values(new_skills)
        .execute(db)?;

    // TODO skill roots
    // skill roots table with multiple entries allowed; make a stat db enum
    // either stat or custom attribute string?
    // need constraint for not more than two?

    // TODO forks
    // have a forks table, with target skill, forks, and fork_descriptions?

    Ok(())
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "skills"]
struct NewSkill {
    name: String,
    page: i32,
    magical: bool,
    tools: ToolRequirement,
    wise: bool,
    skill_type_id: i32,
}

pub fn seed_dwarf_settings(db: &PgConnection) -> StdResult<()> {
    let stock_id = dwarves_id(db)?;

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

fn dwarves_id(db: &PgConnection) -> QueryResult<i32> {
    stocks::table
        .select(stocks::id)
        .filter(&stocks::name.eq("dwarves"))
        .first(db)
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
