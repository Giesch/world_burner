use rocket::http::{ContentType, Status};
use rocket::local::Client;
use serde_json::{from_reader, Value};
use std::collections::HashSet;
use world_burner::routes::lifepaths::LifepathsResponse;

#[test]
fn dwarf_lifepaths() {
    let rocket = world_burner::test_app();
    let client = Client::new(rocket).expect("Rocket client");

    let mut response = client
        .get("/api/lifepaths/dwarves")
        .header(ContentType::JSON)
        .dispatch();

    assert_eq!(response.status(), Status::Ok);

    let body = response.body().expect("response body");
    let json_body: Value = from_reader(body.into_inner()).expect("can't parse value");

    let response: LifepathsResponse =
        serde_json::from_value(json_body).expect("deserialize lifepaths response");

    let names: HashSet<_> = response.lifepaths.into_iter().map(|lp| lp.name).collect();

    let born_lp_names: HashSet<_> = vec![
        "born clansman",
        "born guilder",
        "born artificer",
        "born noble",
    ]
    .into_iter()
    .map(|s| s.to_string())
    .collect();

    assert!(names.is_superset(&born_lp_names))
}
