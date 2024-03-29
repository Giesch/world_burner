use crate::schema::*;

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "stocks"]
pub struct NewStock {
    pub book_id: i32,
    pub name: String,
    pub page: i32,
    pub singular: String,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "skills"]
pub struct NewSkill {
    pub book_id: i32,
    pub name: String,
    pub page: i32,
    pub magical: bool,
    pub training: bool,
    pub wise: bool,
    pub tools: ToolRequirement,
    pub tools_expendable: bool,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "traits"]
pub struct NewTrait {
    pub book_id: i32,
    pub page: i32,
    pub name: String,
    pub cost: Option<i32>,
    pub taip: TraitType,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "lifepath_settings"]
pub struct NewSetting {
    pub book_id: i32,
    pub page: i32,
    pub stock_id: i32,
    pub name: String,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "lifepaths"]
pub struct NewLifepath {
    pub book_id: i32,
    pub lifepath_setting_id: i32,
    pub page: i32,
    pub name: String,
    pub born: bool,

    pub years: Option<i32>,
    pub years_min: Option<i32>,
    pub years_max: Option<i32>,

    pub gen_skill_pts: i32,
    pub skill_pts: i32,
    pub trait_pts: i32,

    pub stat_mod: Option<StatMod>,
    pub stat_mod_val: Option<i32>,

    pub res: Option<i32>,
    pub res_calc: Option<ResCalc>,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "leads"]
pub struct NewLead {
    pub lifepath_id: i32,
    pub setting_id: i32,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "skill_roots"]
pub struct NewSkillRoot {
    pub skill_id: i32,
    pub first_stat_root: Option<Stat>,
    pub second_stat_root: Option<Stat>,
    pub attribute_root: Option<String>,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "lifepath_skill_lists"]
pub struct NewSkillList {
    pub lifepath_id: i32,
    pub list_position: i32,
    pub skill_id: i32,
    pub entryless_skill: Option<String>,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "lifepath_trait_lists"]
pub struct NewTraitList {
    pub lifepath_id: i32,
    pub list_position: i32,
    pub trait_id: Option<i32>,
    pub char_trait: Option<String>,
}

#[derive(Insertable, Debug)]
#[table_name = "lifepath_reqs"]
pub struct NewRequirement {
    pub lifepath_id: i32,
    pub predicate: serde_json::Value,
    pub description: String,
}
