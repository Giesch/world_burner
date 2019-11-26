use crate::schema::*;
use chrono::NaiveDateTime;

#[derive(Queryable, Debug, PartialEq, Eq)]
pub struct CreatedStock {
    pub id: i32,
    pub book_id: i32,
    pub name: String,
    pub singular: String,
    pub page: i32,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Queryable, Debug, PartialEq, Eq)]
pub struct CreatedSkill {
    pub id: i32,
    pub book_id: i32,
    pub page: i32,
    pub name: String,
    pub magical: bool,
    pub training: bool,
    pub wise: bool,
    pub tools: ToolRequirement,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Queryable, Debug, PartialEq, Eq)]
pub struct CreatedTrait {
    pub id: i32,
    pub book_id: i32,
    pub page: i32,
    pub name: String,
    pub cost: Option<i32>,
    pub typ: TraitType,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Queryable, Debug, PartialEq, Eq)]
pub struct CreatedSetting {
    pub id: i32,
    pub book_id: i32,
    pub stock_id: i32,
    pub page: i32,
    pub name: String,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Queryable, Debug, PartialEq, Eq)]
pub struct CreatedLifepath {
    pub id: i32,
    pub book_id: i32,
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
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}
