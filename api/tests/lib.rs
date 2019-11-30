#[macro_use]
extern crate diesel_migrations;

use diesel::prelude::*;
use std::collections::HashSet;
use world_burner::schema::*;
use world_burner::seeding::*;

pub mod setup;
use setup::*;

embed_migrations!();

#[test]
fn test_seed_book_data() {
    recreate_test_db().expect("recreate test db");
    let db = test_connection().expect("get test db conn");
    embedded_migrations::run(&db).expect("running migrations");

    seed_book_data(&db).expect("seeding book data");

    // smoke test

    let _clansman_setting_id: i32 = lifepath_settings::table
        .select(lifepath_settings::id)
        .filter(lifepath_settings::name.eq("clansman"))
        .first(&db)
        .expect("clansman setting should exist");

    {
        use lifepaths::*;

        let tup: (i32, Option<i32>, Option<i32>, i32, i32, i32) = table
            .select((page, years, res, gen_skill_pts, skill_pts, trait_pts))
            .filter(name.eq("born clansman"))
            .first(&db)
            .expect("born clansman should exist");

        assert_eq!(tup.0, 110);
        assert_eq!(tup.1, Some(20));
        assert_eq!(tup.2, Some(10));
        assert_eq!(tup.3, 3);
        assert_eq!(tup.4, 0);
        assert_eq!(tup.5, 1);
    }

    // no non-wise or history without an entry

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

    assert_eq!(orphan_skill_names.len(), 0);
}
