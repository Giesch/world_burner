use ron::de;
use std::fmt;
use std::fs;
use std::path::Path;

use super::StdResult;
use crate::schema;
use crate::schema::Stat;
use crate::schema::ToolRequirement;
use crate::schema::TraitType;

const GOLD_SKILLS_PATH: &str = "gold_revised/skills.ron";
const GOLD_TRAITS_PATH: &str = "gold_revised/traits.ron";
const GOLD_STOCKS_PATH: &str = "gold_revised/stocks.ron";

pub fn read_skills() -> de::Result<Vec<Skill>> {
    let skills = fs::read_to_string(GOLD_SKILLS_PATH)?;
    de::from_str(&skills).map(|skills: Skills| skills.skills)
}

pub fn read_traits() -> de::Result<Vec<Trait>> {
    let traits = fs::read_to_string(GOLD_TRAITS_PATH)?;
    de::from_str(&traits).map(|traits: Traits| traits.traits)
}

pub fn read_stock_settings(book_dir: &str, stock_prefix: &str) -> StdResult<Vec<LifepathSetting>> {
    let dir = format!("{}/{}_settings", book_dir, stock_prefix);
    let dir = Path::new(&dir);

    let rons = all_ron_files(dir)?;

    let mut settings = Vec::new();
    for input in rons {
        let setting = de::from_str::<LifepathSetting>(&input)?;
        settings.push(setting);
    }

    Ok(settings)
}

fn all_ron_files(dir: &Path) -> StdResult<Vec<String>> {
    let mut result = Vec::new();
    if !dir.is_dir() {
        return Ok(vec![]);
    }

    for entry in fs::read_dir(dir)? {
        let entry = entry?;
        let path = entry.path();
        let is_ron = !path.is_dir() && path.extension().and_then(|s| s.to_str()) == Some("ron");
        if is_ron {
            let ron = fs::read_to_string(path)?;
            result.push(ron);
        }
    }

    Ok(result)
}

pub fn read_stocks() -> de::Result<Vec<Stock>> {
    let gold_stocks = fs::read_to_string(GOLD_STOCKS_PATH)?;
    de::from_str(&gold_stocks).map(|stocks: Stocks| stocks.stocks)
}

#[derive(Deserialize, Debug)]
struct Skills {
    skills: Vec<Skill>,
}

#[derive(Deserialize, Debug)]
pub struct Skill {
    pub name: String,
    pub page: i32,
    pub root: SkillRoot,
    #[serde(default)]
    pub magical: bool,
    #[serde(default)]
    pub training: bool,
    pub tools: ToolRequirement,
    #[serde(default)]
    pub tools_expendable: bool,
    #[serde(default)]
    pub restrictions: Restriction,
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq)]
pub enum StatMod {
    Physical(i32),
    Mental(i32),
    Either(i32),
    Both(i32),
    None,
}

impl StatMod {
    pub fn stat_mod_type(&self) -> Option<schema::StatMod> {
        match self {
            Self::Physical(_) => Some(schema::StatMod::Physical),
            Self::Mental(_) => Some(schema::StatMod::Mental),
            Self::Either(_) => Some(schema::StatMod::Either),
            Self::Both(_) => Some(schema::StatMod::Both),
            Self::None => None,
        }
    }

    pub fn stat_mod_val(&self) -> Option<i32> {
        match self {
            Self::Physical(val) => Some(*val),
            Self::Mental(val) => Some(*val),
            Self::Either(val) => Some(*val),
            Self::Both(val) => Some(*val),
            Self::None => None,
        }
    }
}

impl Default for StatMod {
    fn default() -> Self {
        StatMod::None
    }
}

/// This is specific to book data, don't use it elsewhere
#[derive(Deserialize, Debug, PartialEq, Eq)]
pub struct Lifepath {
    pub name: String,
    pub page: i32,
    #[serde(default)]
    pub born: bool,

    // for these two, None means the one special lifepath
    pub years: Option<i32>,
    pub res: Option<i32>,

    #[serde(default)]
    pub stat_mod: StatMod,
    #[serde(default)]
    pub leads: Vec<String>,
    #[serde(default)]
    pub gen_skill_pts: i32,
    pub skill_pts: i32,
    #[serde(default)]
    pub trait_pts: i32,
    #[serde(default)]
    pub skills: Vec<String>,
    #[serde(default)]
    pub traits: Vec<String>,
    #[serde(default)]
    pub requires: Option<Requirement>,
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub struct LifepathSetting {
    pub name: String,
    pub page: i32,
    pub lifepaths: Vec<Lifepath>,
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub struct Stock {
    pub name: String,
    pub singular: String,
    pub page: i32,
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
struct Stocks {
    stocks: Vec<Stock>,
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
struct LifepathSettings {
    settings: Vec<Setting>,
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub struct Setting {
    pub name: String,
    pub page: u16,
}

#[derive(Deserialize, Debug, Clone)]
pub enum SkillRoot {
    Single(Stat),
    Pair(Stat, Stat),
    Attribute(AttributeRoot),
}

#[derive(Deserialize, Debug, Clone)]
pub enum AttributeRoot {
    Hatred,
}

impl fmt::Display for AttributeRoot {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let s = match self {
            Self::Hatred => "hatred",
        };
        write!(f, "{}", s)
    }
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub enum Restriction {
    None,
    Only(StockRestriction, #[serde(default)] RestrictionTiming),
    Any(Vec<StockRestriction>, #[serde(default)] RestrictionTiming),
}

impl Default for Restriction {
    fn default() -> Self {
        Self::None
    }
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub enum RestrictionTiming {
    CharBurning,
    Ever,
}

impl Default for RestrictionTiming {
    fn default() -> Self {
        Self::Ever
    }
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub enum StockRestriction {
    Dwarves,
    Elves,
    Humans,
    Orcs,
    Roden,
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub struct Traits {
    traits: Vec<Trait>,
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub enum Trait {
    Die {
        name: String,
        page: i32,
        #[serde(default)]
        cost: Option<i32>,
    },
    CallOn {
        name: String,
        page: i32,
        #[serde(default)]
        cost: Option<i32>,
    },
    Char {
        name: String,
        page: i32,
    },
}

impl Trait {
    pub fn page(&self) -> i32 {
        match self {
            Self::Die { page, .. } => *page,
            Self::CallOn { page, .. } => *page,
            Self::Char { page, .. } => *page,
        }
    }

    pub fn name(&self) -> String {
        match self {
            Self::Die { name, .. } => name.to_string(),
            Self::CallOn { name, .. } => name.to_string(),
            Self::Char { name, .. } => name.to_string(),
        }
    }

    pub fn cost(&self) -> Option<i32> {
        match self {
            Self::Die { cost, .. } => *cost,
            Self::CallOn { cost, .. } => *cost,
            Self::Char { .. } => Some(1),
        }
    }

    pub fn trait_type(&self) -> TraitType {
        match self {
            Self::Die { .. } => TraitType::Die,
            Self::CallOn { .. } => TraitType::CallOn,
            Self::Char { .. } => TraitType::Char,
        }
    }
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq)]
pub struct Requirement {
    pub req: LifepathReq,
    pub desc: String,
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq, Clone)]
pub enum LifepathReq {
    // requires a specific previous lifepath n times
    LP(String, #[serde(default = "one")] i32),
    // requires n previous lifepaths of any kind
    PreviousLifepaths(i32),
    // requires n lifepaths from a setting
    Setting(i32, String),
    // met if any subreq is met
    Any(Vec<LifepathReq>),
    // met only if all subreqs are met
    All(Vec<LifepathReq>),
}

fn one() -> i32 {
    1
}
