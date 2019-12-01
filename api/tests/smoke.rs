use diesel::prelude::*;
use world_burner::schema::*;

mod common;

#[test]
fn born_clansman() {
    let db = common::test_connection();

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
