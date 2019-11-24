use crate::schema::*;
use chrono::NaiveDateTime;

#[derive(Queryable, Debug, PartialEq, Eq)]
pub struct CreatedStock {
    pub id: i32,
    pub book: Book,
    pub name: String,
    pub singular: String,
    pub page: i32,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Queryable, Debug, PartialEq, Eq)]
pub struct CreatedSkill {
    pub id: i32,
    pub skill_type_id: i32,
    pub book: Book,
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
pub struct CreatedSetting {
    pub id: i32,
    pub book: Book,
    pub stock_id: i32,
    pub page: i32,
    pub name: String,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}
