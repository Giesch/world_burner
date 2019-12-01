use dotenv::dotenv;
use std::env;
use diesel::pg::PgConnection;
use diesel::prelude::*;

pub fn test_connection() -> PgConnection {
    dotenv().expect("use dotenv");

    let local_db_url = env::var("LOCAL_DATABASE_URL").expect("get local db url");
    let test_db_name = env::var("TEST_DATABASE_NAME").expect("get test database name");
    let test_url = format!("{}/{}", local_db_url, test_db_name);

    PgConnection::establish(&test_url).expect("establish test connection")
}
