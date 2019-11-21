use diesel::pg::PgConnection;
use diesel::prelude::*;
use dotenv::dotenv;
use world_burner::seeding::seed_book_data;

type StdResult<T> = Result<T, Box<dyn std::error::Error>>;

/// This is the task for loading the book data RON files into the database.
fn main() -> StdResult<()> {
    dotenv().ok();
    let url = std::env::var("DATABASE_URL")?;
    let db = PgConnection::establish(&url)?;
    seed_book_data(&db)
}
