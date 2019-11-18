use dotenv::dotenv;
use world_burner::seeding::seed_book_data;

type StdResult<T> = Result<T, Box<dyn std::error::Error>>;

/// This is the task for loading the book data RON files into the database.
fn main() -> StdResult<()> {
    dotenv().ok();
    seed_book_data()
}
