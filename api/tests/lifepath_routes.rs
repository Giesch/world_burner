use parking_lot::Mutex;
use rocket::http::{ContentType, Status};
use rocket::local::Client;
use serde_json::{from_reader, Value};
use std::collections::HashSet;
use world_burner::db::DbConn;
use world_burner::models::lifepaths::Lifepath;

// run_test macro taken from here:
// https://github.com/SergioBenitez/Rocket/blob/master/examples/todo/src/tests.rs
// details here:
// https://github.com/SergioBenitez/Rocket/issues/167
// https://github.com/SergioBenitez/Rocket/issues/697

// We use a lock to synchronize between tests so DB operations don't collide.
// For now. In the future, we'll have a nice way to run each test in a DB
// transaction so we can regain concurrency.
static DB_LOCK: Mutex<()> = Mutex::new(());

macro_rules! run_test {
    (|$client:ident, $conn:ident| $block:expr) => {{
        let _lock = DB_LOCK.lock();
        let rocket = world_burner::app();
        let db = DbConn::get_one(&rocket);
        let $client = Client::new(rocket).expect("Rocket client");
        let $conn = db.expect("failed to get database connection for testing");

        // assert!(delete_all(&$conn), "failed to delete all users for testing");

        $block
    }};
}

#[test]
fn born_lifepaths() {
    run_test!(|client, _db| {
        let mut response = client
            .get("/api/lifepaths/born")
            .header(ContentType::JSON)
            .dispatch();

        assert_eq!(response.status(), Status::Ok);

        let body = response.body().expect("response body");
        let json_body: Value = from_reader(body.into_inner()).expect("can't parse value");
        let lifepaths = json_body.get("lifepaths").expect("response has lifepaths");
        let lifepaths: Vec<Lifepath> =
            serde_json::from_value(lifepaths.clone()).expect("deserialize lifepaths");

        let names: HashSet<_> = lifepaths.iter().map(|lp| lp.name.clone()).collect();
        let expected_names: HashSet<_> = vec![
            "born clansman",
            "born guilder",
            "born artificer",
            "born noble",
        ]
        .into_iter()
        .map(|s| s.to_string())
        .collect();

        assert_eq!(names, expected_names);
    });
}
