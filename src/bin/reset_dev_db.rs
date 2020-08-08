#[macro_use]
extern crate diesel_migrations;

use dotenv::dotenv;
use std::env;

use diesel::pg::PgConnection;
use diesel::prelude::*;
use world_burner::seeding::seed_book_data;

type StdResult<T> = Result<T, Box<dyn std::error::Error>>;

embed_migrations!();

// TODO share code with recreate_test_db
fn main() -> StdResult<()> {
    dotenv()?;

    println!("Recreating dev database...");
    recreate_dev_db()?;

    println!("Running migrations...");
    let db = dev_connection()?;
    embedded_migrations::run(&db).expect("running migrations");

    println!("Seeding book data...");
    seed_book_data(&db)?;

    Ok(())
}

fn recreate_dev_db() -> StdResult<()> {
    let url = env::var("LOCAL_DATABASE_URL")?;
    let db = PgConnection::establish(&url)?;
    let dev_db_name = env::var("DEV_DATABASE_NAME")?;

    let drop = format!("DROP DATABASE IF EXISTS {}", dev_db_name);
    diesel::sql_query(drop).execute(&db)?;

    let create = format!("CREATE DATABASE {}", dev_db_name);
    diesel::sql_query(create).execute(&db)?;

    Ok(())
}

fn dev_connection() -> StdResult<PgConnection> {
    let local_db_url = env::var("LOCAL_DATABASE_URL")?;
    let dev_db_name = env::var("DEV_DATABASE_NAME")?;
    let dev_db_url = format!("{}/{}", local_db_url, dev_db_name);
    let db = PgConnection::establish(&dev_db_url)?;

    Ok(db)
}
