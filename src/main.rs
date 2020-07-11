#[macro_use]
extern crate diesel_migrations;

use diesel::pg::PgConnection;
use diesel::prelude::*;
use dotenv::dotenv;
use std::env;

embed_migrations!();

fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenv().ok();

    let db_url = env::var("DATABASE_URL")?;
    let db = PgConnection::establish(&db_url)?;
    embedded_migrations::run(&db)?;

    world_burner::app().launch();

    Ok(())
}
