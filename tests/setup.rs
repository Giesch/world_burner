use dotenv::dotenv;
use std::env;

use diesel::pg::PgConnection;
use diesel::prelude::*;

type StdResult<T> = Result<T, Box<dyn std::error::Error>>;

pub fn recreate_test_db() -> StdResult<()> {
    dotenv()?;
    let url = env::var("LOCAL_DATABASE_URL")?;
    let db = PgConnection::establish(&url)?;
    let test_db_name = env::var("TEST_DATABASE_NAME")?;

    let drop = format!("DROP DATABASE IF EXISTS {}", test_db_name);
    diesel::sql_query(drop).execute(&db)?;

    let create = format!("CREATE DATABASE {}", test_db_name);
    diesel::sql_query(create).execute(&db)?;

    Ok(())
}

pub fn test_connection() -> StdResult<PgConnection> {
    dotenv()?;
    let local_db_url = env::var("LOCAL_DATABASE_URL")?;
    let test_db_name = env::var("TEST_DATABASE_NAME")?;
    let test_url = format!("{}/{}", local_db_url, test_db_name);
    let db = PgConnection::establish(&test_url)?;
    Ok(db)
}
