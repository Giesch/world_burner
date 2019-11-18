//! Functions for loading book data.

use diesel::pg::PgConnection;
use diesel::prelude::*;

use crate::schema::{lifepath_settings, stocks, BookType};

type StdResult<T> = Result<T, Box<dyn std::error::Error>>;

/// This is the function for loading all RON files in both dev and prod.
/// It expects that the environment variable DATABASE_URL is set,
/// and that migrations have been run.
pub fn seed_book_data() -> StdResult<()> {
    let url = std::env::var("DATABASE_URL")?;
    let db = PgConnection::establish(&url)?;

    seed_stocks(&db)?;
    seed_dwarf_settings(&db)?;

    Ok(())
}

pub fn seed_stocks(db: &PgConnection) -> StdResult<()> {
    let stocks: Vec<_> = read_stocks()?
        .stocks
        .into_iter()
        .map(|stock| NewStock {
            book: BookType::GoldRevised,
            name: stock.name,
            page: stock.page,
        })
        .collect();

    diesel::insert_into(stocks::table)
        .values(stocks)
        .execute(db)?;

    Ok(())
}

fn read_stocks() -> ron::de::Result<Stocks> {
    let stocks = include_str!("../gold_revised/stocks.ron");
    ron::de::from_str(stocks)
}

pub fn seed_dwarf_settings(db: &PgConnection) -> StdResult<()> {
    let stock_id = dwarves_id(db)?;

    let settings: Vec<_> = read_dwarf_settings()?
        .settings
        .into_iter()
        .map(|setting| NewSetting {
            stock_id,
            book: BookType::GoldRevised,
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

fn read_dwarf_settings() -> ron::de::Result<DwarfSettings> {
    let dwarf_settings = include_str!("../gold_revised/dwarf_settings.ron");
    ron::de::from_str(dwarf_settings)
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
struct Stock {
    pub name: String,
    pub page: i32,
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
struct Stocks {
    pub stocks: Vec<Stock>,
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub struct DwarfSettings {
    settings: Vec<Setting>,
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub struct Setting {
    name: String,
    page: u16,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "stocks"]
pub struct NewStock {
    name: String,
    book: BookType,
    page: i32,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "lifepath_settings"]
pub struct NewSetting {
    book: BookType,
    page: i32,
    stock_id: i32,
    name: String,
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq)]
pub struct DwarfLifepath {
    name: String,
    years: u32,
    res: u32,
    #[serde(default)]
    stat: StatMod,
    #[serde(default)]
    leads: Vec<DwarfLead>,
    #[serde(default)]
    general_skill_pts: u8,
    #[serde(default)]
    skill_pts: u8,
    #[serde(default)]
    trait_pts: u8,
    #[serde(default)]
    skills: Vec<String>,
    #[serde(default)]
    traits: Vec<String>,
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq)]
pub enum DwarfLead {
    Any,
    Clansman,
    Guilder,
    Artificer,
    Noble,
    Host,
    Outcast,
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq)]
pub enum StatMod {
    Physical(i8),
    Mental(i8),
    Either(i8),
    Both(i8),
}

impl Default for StatMod {
    fn default() -> Self {
        StatMod::Either(0)
    }
}
