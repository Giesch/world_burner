#[macro_use]
extern crate diesel_migrations;

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
}
