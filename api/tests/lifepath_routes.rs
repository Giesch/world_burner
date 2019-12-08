use rocket::http::{ContentType, Status};
use rocket::local::Client;
use serde_json::{from_reader, Value};
use std::collections::HashSet;
use world_burner::routes::lifepaths::LifepathsResponse;

#[test]
fn born_lifepaths() {
    let rocket = world_burner::app();
    let client = Client::new(rocket).expect("Rocket client");

    let json = r#"{
        "born": true
    }"#;

    let mut response = client
        .post("/api/lifepaths/search")
        .header(ContentType::JSON)
        .body(json)
        .dispatch();

    assert_eq!(response.status(), Status::Ok);

    let body = response.body().expect("response body");
    let json_body: Value = from_reader(body.into_inner()).expect("can't parse value");
    let response: LifepathsResponse =
        serde_json::from_value(json_body).expect("deserialize lifepaths response");

    let names: HashSet<_> = response.lifepaths.into_iter().map(|lp| lp.name).collect();

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
}
