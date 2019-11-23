use ron::de;

use crate::schema::Stat;
use crate::schema::ToolRequirement;
use crate::schema::TraitType;

pub fn read_traits() -> de::Result<Vec<Trait>> {
    let traits = include_str!("../../gold_revised/traits.ron");
    de::from_str(traits).map(|traits: Traits| traits.traits)
}

pub fn read_skills() -> de::Result<Vec<Skill>> {
    let skills = include_str!("../../gold_revised/skills.ron");
    de::from_str(skills).map(|skills: Skills| skills.skills)
}

pub fn read_dwarf_settings() -> de::Result<Vec<Setting>> {
    let dwarf_settings = include_str!("../../gold_revised/dwarf_settings.ron");
    de::from_str(dwarf_settings).map(|settings: LifepathSettings| settings.settings)
}

pub fn read_stocks() -> de::Result<Vec<Stock>> {
    let stocks = include_str!("../../gold_revised/stocks.ron");
    de::from_str(stocks).map(|stocks: Stocks| stocks.stocks)
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
    pub forks: Vec<String>,
    pub skill_type: SkillType,
    pub tools: ToolRequirement,
    #[serde(default)]
    pub restrictions: Vec<Restriction>,
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq)]
pub enum StatMod {
    Physical(i32),
    Mental(i32),
    Either(i32),
    Both(i32),
    None,
}

impl Default for StatMod {
    fn default() -> Self {
        StatMod::None
    }
}

#[derive(Deserialize, Serialize, Debug, PartialEq, Eq)]
pub struct Lifepath {
    name: String,
    years: u32,
    res: u32,
    #[serde(default)]
    stat: StatMod,
    #[serde(default)]
    leads: Vec<DwarfLead>,
    #[serde(default)]
    general_skill_pts: u8,
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

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub struct Stock {
    pub name: String,
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

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub enum SkillType {
    Academic,
    Artisan,
    Artist,
    Craftsman,
    Forester,
    Martial,
    Medicinal,
    Military,
    Musical,
    Peasant,
    Physical,
    SchoolOfThought,
    Seafaring,
    Social,
    Sorcerous,
    Special,
}

impl SkillType {
    pub fn db_name(&self) -> &str {
        use SkillType::*;
        match self {
            Academic => "academic",
            Artisan => "artisan",
            Artist => "artist",
            Craftsman => "craftsman",
            Forester => "forester",
            Martial => "martial",
            Medicinal => "medicinal",
            Military => "military",
            Musical => "musical",
            Peasant => "peasant",
            Physical => "physical",
            SchoolOfThought => "school_of_thought",
            Seafaring => "seafaring",
            Social => "social",
            Sorcerous => "sorcerous",
            Special => "special",
        }
    }
}

#[derive(Deserialize, Debug, Clone)]
pub enum SkillRoot {
    Single(Stat),
    Pair(Stat, Stat),
    Attribute(String),
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub enum Restriction {
    CB(StockRestriction),
    Only(StockRestriction),
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
pub enum StockRestriction {
    Dwarves,
    Elves,
    Humans,
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
        #[serde(default)]
        page: Option<i32>,
    },
}

impl Trait {
    pub fn page(&self) -> Option<i32> {
        match self {
            Self::Die { page, .. } => Some(*page),
            Self::CallOn { page, .. } => Some(*page),
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
