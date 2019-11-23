#[macro_use]
extern crate diesel_migrations;

use diesel::prelude::*;
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

    let _clansman_setting_id: i32 = lifepath_settings::table
        .select(lifepath_settings::id)
        .filter(lifepath_settings::name.eq("clansman"))
        .first(&db)
        .expect("clansman setting should exist");

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
