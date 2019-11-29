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
    Workshop,
    Weapon,
    TravelingGear,
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

#[PgType = "trait_type"]
#[DieselType = "TraitTypeMapping"]
#[derive(Deserialize, Debug, PartialEq, Eq, Clone, Copy, DbEnum)]
pub enum TraitType {
    Char,
    CallOn,
    Die,
}

table! {
    use diesel::sql_types::*;

    books (id) {
        id -> Int4,
        abbrev -> Text,
        title -> Text,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;

    leads (lifepath_id, setting_id) {
        lifepath_id -> Int4,
        setting_id -> Int4,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;

    lifepath_reqs (lifepath_id) {
        lifepath_id -> Int4,
        requirement -> Jsonb,
        description -> Text,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;
    use super::StatModTypeMapping;

    lifepaths (id) {
        id -> Int4,
        book_id -> Int4,
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

    lifepath_settings (id) {
        id -> Int4,
        book_id -> Int4,
        stock_id -> Int4,
        page -> Int4,
        name -> Text,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;

    lifepath_skill_lists (lifepath_id, list_position) {
        lifepath_id -> Int4,
        list_position -> Int4,
        skill_id -> Int4,
        entryless_skill -> Nullable<Text>,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;

    lifepath_trait_lists (lifepath_id, list_position) {
        lifepath_id -> Int4,
        list_position -> Int4,
        trait_id -> Nullable<Int4>,
        char_trait -> Nullable<Text>,
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
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;
    use super::ToolRequirementMapping;

    skills (id) {
        id -> Int4,
        book_id -> Int4,
        page -> Int4,
        name -> Text,
        magical -> Bool,
        training -> Bool,
        wise -> Bool,
        tools -> ToolRequirementMapping,
        tools_expendable -> Bool,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;

    stocks (id) {
        id -> Int4,
        book_id -> Int4,
        name -> Text,
        singular -> Text,
        page -> Int4,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    use diesel::sql_types::*;
    use super::TraitTypeMapping;

    traits (id) {
        id -> Int4,
        book_id -> Int4,
        page -> Int4,
        name -> Text,
        cost -> Nullable<Int4>,
        typ -> TraitTypeMapping,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

joinable!(leads -> lifepath_settings (setting_id));
joinable!(leads -> lifepaths (lifepath_id));
joinable!(lifepath_reqs -> lifepaths (lifepath_id));
joinable!(lifepath_settings -> books (book_id));
joinable!(lifepath_settings -> stocks (stock_id));
joinable!(lifepath_skill_lists -> lifepaths (lifepath_id));
joinable!(lifepath_skill_lists -> skills (skill_id));
joinable!(lifepath_trait_lists -> lifepaths (lifepath_id));
joinable!(lifepath_trait_lists -> traits (trait_id));
joinable!(lifepaths -> books (book_id));
joinable!(lifepaths -> lifepath_settings (lifepath_setting_id));
joinable!(skill_roots -> skills (skill_id));
joinable!(skills -> books (book_id));
joinable!(stocks -> books (book_id));
joinable!(traits -> books (book_id));

allow_tables_to_appear_in_same_query!(
    books,
    leads,
    lifepath_reqs,
    lifepaths,
    lifepath_settings,
    lifepath_skill_lists,
    lifepath_trait_lists,
    skill_roots,
    skills,
    stocks,
    traits,
);
