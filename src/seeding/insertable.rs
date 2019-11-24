use crate::schema::*;

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "stocks"]
pub struct NewStock {
    pub name: String,
    pub book: Book,
    pub page: i32,
    pub singular: String,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "skills"]
pub struct NewSkill {
    pub name: String,
    pub book: Book,
    pub page: i32,
    pub magical: bool,
    pub tools: ToolRequirement,
    pub wise: bool,
    pub skill_type_id: i32,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "traits"]
pub struct NewTrait {
    pub book: Book,
    pub page: i32,
    pub name: String,
    pub cost: Option<i32>,
    pub typ: TraitType,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "lifepath_settings"]
pub struct NewSetting {
    pub book: Book,
    pub page: i32,
    pub stock_id: i32,
    pub name: String,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "lifepaths"]
pub struct NewLifepath {
    pub book: Book,
    pub lifepath_setting_id: i32,
    pub page: i32,
    pub name: String,

    pub years: Option<i32>,
    pub years_min: Option<i32>,
    pub years_max: Option<i32>,

    pub gen_skill_pts: i32,
    pub skill_pts: i32,
    pub trait_pts: i32,

    pub stat_mod: Option<StatMod>,
    pub stat_mod_val: Option<i32>,

    pub res: Option<i32>,
    pub res_calc: Option<String>,
}

#[derive(Insertable, Debug, PartialEq, Eq)]
#[table_name = "skill_roots"]
pub struct NewSkillRoot {
    pub skill_id: i32,
    pub first_stat_root: Option<Stat>,
    pub second_stat_root: Option<Stat>,
    pub attribute_root: Option<String>,
}
