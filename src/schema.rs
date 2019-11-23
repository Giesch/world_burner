#[PgType = "book_type"]
#[DieselType = "BookTypeMapping"]
#[derive(Deserialize, Debug, PartialEq, Eq, Clone, Copy, DbEnum)]
pub enum Book {
    GoldRevised,
    Codex,
}

#[PgType = "stat_mod_type"]
#[DieselType = "StatModTypeMapping"]
#[derive(Deserialize, Debug, PartialEq, Eq, Clone, Copy, DbEnum)]
pub enum StatMod {
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

#[PgType = "stat_type"]
#[DieselType = "StatTypeMapping"]
#[derive(Deserialize, Debug, PartialEq, Eq, Clone, Copy, DbEnum)]
pub enum Stat {
    Will,
    Perception,
    Power,
    Agility,
    Speed,
    Forte,
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

    skill_forks (skill_id, fork_id) {
        skill_id -> Int4,
        fork_desc -> Nullable<Text>,
        fork_id -> Int4,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;
    use super::StatTypeMapping;

    skill_roots (skill_id) {
        skill_id -> Int4,
        first_stat_root -> Nullable<StatTypeMapping>,
        second_stat_root -> Nullable<StatTypeMapping>,
        attribute_root -> Nullable<Text>,
    }
}

table! {
    use diesel::sql_types::*;
    use super::BookTypeMapping;
    use super::ToolRequirementMapping;

    skills (id) {
        id -> Int4,
        skill_type_id -> Int4,
        book -> BookTypeMapping,
        page -> Int4,
        name -> Text,
        magical -> Bool,
        wise -> Bool,
        tools -> ToolRequirementMapping,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;

    skill_types (id) {
        id -> Int4,
        name -> Text,
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
joinable!(skill_roots -> skills (skill_id));
joinable!(skills -> skill_types (skill_type_id));

allow_tables_to_appear_in_same_query!(
    books,
    lifepaths,
    lifepath_settings,
    lifepath_skill_lists,
    lifepath_trait_lists,
    skill_forks,
    skill_roots,
    skills,
    skill_types,
    stocks,
    traits,
);
