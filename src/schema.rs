#[PgType = "book_type"]
#[DieselType = "BookTypeMapping"]
#[derive(Debug, PartialEq, Eq, DbEnum)]
pub enum BookType {
    GoldRevised,
    Codex,
}

#[PgType = "stat_mod_type"]
#[DieselType = "StatModTypeMapping"]
#[derive(Deserialize, Debug, PartialEq, Eq, Clone, Copy, DbEnum)]
pub enum StatModType {
    Physical,
    Mental,
    Either,
    Both,
}

#[PgType = "tool_req"]
#[DieselType = "ToolRequirementMapping"]
#[derive(Deserialize, Debug, PartialEq, Eq, Clone, Copy, DbEnum)]
pub enum ToolRequirement {
    Yes,
    No,
    Expendable,
    Workshop,
}

table! {
    use diesel::sql_types::*;
    use super::BookTypeMapping;

    books (book) {
        book -> BookTypeMapping,
        abbrev -> Text,
        title -> Text,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;
    use super::BookTypeMapping;
    use super::StatModTypeMapping;

    lifepaths (id) {
        id -> Int4,
        book -> BookTypeMapping,
        lifepath_setting_id -> Int4,
        page -> Int4,
        name -> Text,
        years -> Nullable<Int4>,
        years_min -> Nullable<Int4>,
        years_max -> Nullable<Int4>,
        gen_skill_pts -> Int4,
        skill_pts -> Int4,
        trait_pts -> Int4,
        stat_mod -> Nullable<StatModTypeMapping>,
        stat_mod_val -> Nullable<Int4>,
        res -> Nullable<Int4>,
        res_calc -> Nullable<Text>,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;
    use super::BookTypeMapping;

    lifepath_settings (id) {
        id -> Int4,
        book -> BookTypeMapping,
        stock_id -> Int4,
        page -> Int4,
        name -> Text,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;

    lifepath_skill_lists (lifepath_id, list_position, skill_id) {
        lifepath_id -> Int4,
        list_position -> Int4,
        skill_id -> Int4,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;

    lifepath_trait_lists (lifepath_id, list_position, trait_id) {
        lifepath_id -> Int4,
        list_position -> Int4,
        trait_id -> Int4,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;
    use super::BookTypeMapping;
    use super::ToolRequirementMapping;

    skills (id) {
        id -> Int4,
        book -> BookTypeMapping,
        page -> Int4,
        name -> Text,
        magical -> Bool,
        tools -> ToolRequirementMapping,
        wise -> Bool,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;
    use super::BookTypeMapping;

    stocks (id) {
        id -> Int4,
        book -> BookTypeMapping,
        name -> Text,
        page -> Int4,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;
    use super::BookTypeMapping;

    traits (id) {
        id -> Int4,
        book -> BookTypeMapping,
        page -> Int4,
        name -> Text,
        cost -> Nullable<Int4>,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

joinable!(lifepath_settings -> stocks (stock_id));
joinable!(lifepath_skill_lists -> lifepaths (lifepath_id));
joinable!(lifepath_skill_lists -> skills (skill_id));
joinable!(lifepath_trait_lists -> lifepaths (lifepath_id));
joinable!(lifepath_trait_lists -> traits (trait_id));
joinable!(lifepaths -> lifepath_settings (lifepath_setting_id));

allow_tables_to_appear_in_same_query!(
    books,
    lifepaths,
    lifepath_settings,
    lifepath_skill_lists,
    lifepath_trait_lists,
    skills,
    stocks,
    traits,
);
