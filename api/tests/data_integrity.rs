use diesel::prelude::*;
use std::collections::HashSet;
use world_burner::schema::*;

mod common;

#[test]
fn no_entryless_non_knowledge_skills() {
    let db = common::test_connection();

    let entryless_skills = lifepath_skill_lists::table
        .select(lifepath_skill_lists::entryless_skill)
        .load::<Option<String>>(&db)
        .expect("load entryless skills");

    let entryless_skill_names: HashSet<_> = entryless_skills
        .iter()
        .filter_map(|name| name.as_ref())
        .collect();

    let orphan_skill_names: Vec<_> = entryless_skill_names
        .iter()
        .filter(|name| !name.ends_with("-wise"))
        .filter(|name| !name.ends_with("history"))
        .collect();

    println!("{:#?}", orphan_skill_names);
    assert_eq!(orphan_skill_names.len(), 0);
}
