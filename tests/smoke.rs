use diesel::prelude::*;
use world_burner::schema::*;

mod common;

#[test]
fn born_clansman() {
    let db = common::test_connection();

    let tup: (i32, Option<i32>, Option<i32>, Option<i32>, i32, i32) = lifepaths::table
        .select((
            lifepaths::page,
            lifepaths::years,
            lifepaths::res,
            lifepaths::gen_skill_pts,
            lifepaths::skill_pts,
            lifepaths::trait_pts,
        ))
        .filter(lifepaths::name.eq("born clansman"))
        .first(&db)
        .expect("born clansman should exist");

    assert_eq!(tup.0, 110);
    assert_eq!(tup.1, Some(20));
    assert_eq!(tup.2, Some(10));
    assert_eq!(tup.3, Some(3));
    assert_eq!(tup.4, 0);
    assert_eq!(tup.5, 1);
}
