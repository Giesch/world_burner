#[macro_use]
extern crate diesel_migrations;

use dotenv::dotenv;
use std::env;

use diesel::pg::PgConnection;
use diesel::prelude::*;
use world_burner::seeding::seed_book_data;

type StdResult<T> = Result<T, Box<dyn std::error::Error>>;

embed_migrations!();

/// This is the task for resetting the test database before a 'cargo test' run.
fn main() -> StdResult<()> {
    dotenv()?;

    println!("Recreating test database...");
    recreate_test_db()?;

    println!("Running migrations...");
    let db = test_connection()?;
    embedded_migrations::run(&db).expect("running migrations");

    println!("Seeding book data...");
    seed_book_data(&db)?;

    Ok(())
}

fn recreate_test_db() -> StdResult<()> {
    let url = env::var("LOCAL_DATABASE_URL")?;
    let db = PgConnection::establish(&url)?;
    let test_db_name = env::var("TEST_DATABASE_NAME")?;

    let drop = format!("DROP DATABASE IF EXISTS {}", test_db_name);
    diesel::sql_query(drop).execute(&db)?;

    let create = format!("CREATE DATABASE {}", test_db_name);
    diesel::sql_query(create).execute(&db)?;

    Ok(())
}

fn test_connection() -> StdResult<PgConnection> {
    let local_db_url = env::var("LOCAL_DATABASE_URL")?;
    let test_db_name = env::var("TEST_DATABASE_NAME")?;
    let test_db_url = format!("{}/{}", local_db_url, test_db_name);
    let db = PgConnection::establish(&test_db_url)?;

    Ok(db)
}
