table! {
    books (id) {
        id -> Int4,
        title -> Text,
        abbreviation -> Text,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    lifepaths (id) {
        id -> Int4,
        book_id -> Int4,
        lifepath_setting_id -> Int4,
        page_number -> Int4,
        name -> Text,
        years -> Nullable<Int4>,
        skill_pts -> Int4,
        trait_pts -> Int4,
        physical_modifier -> Int4,
        mental_modifier -> Int4,
        optional_modifier -> Int4,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    lifepath_settings (id) {
        id -> Int4,
        book_id -> Int4,
        stock_id -> Int4,
        page_number -> Int4,
        name -> Text,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    lifepath_skill_lists (lifepath_id, list_position, skill_id) {
        lifepath_id -> Int4,
        list_position -> Int4,
        skill_id -> Int4,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    lifepath_trait_lists (lifepath_id, list_position, trait_id) {
        lifepath_id -> Int4,
        list_position -> Int4,
        trait_id -> Int4,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    skills (id) {
        id -> Int4,
        book_id -> Int4,
        page_number -> Int4,
        name -> Text,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    stocks (id) {
        id -> Int4,
        book_id -> Int4,
        name -> Text,
        page_number -> Int4,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

table! {
    traits (id) {
        id -> Int4,
        book_id -> Int4,
        page_number -> Int4,
        name -> Text,
        cost -> Nullable<Int4>,
        created_at -> Timestamptz,
        updated_at -> Timestamptz,
    }
}

joinable!(lifepath_settings -> books (book_id));
joinable!(lifepath_settings -> stocks (stock_id));
joinable!(lifepath_skill_lists -> lifepaths (lifepath_id));
joinable!(lifepath_skill_lists -> skills (skill_id));
joinable!(lifepath_trait_lists -> lifepaths (lifepath_id));
joinable!(lifepath_trait_lists -> traits (trait_id));
joinable!(lifepaths -> books (book_id));
joinable!(lifepaths -> lifepath_settings (lifepath_setting_id));
joinable!(skills -> books (book_id));
joinable!(stocks -> books (book_id));
joinable!(traits -> books (book_id));

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
