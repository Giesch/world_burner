use rocket_contrib::json::Json;

#[derive(Deserialize)]
pub struct LifepathFilters {
    born: Option<bool>,
}

// want to include current lifepaths here later
#[post("/lifepaths/search", format = "json", data = "<filters>")]
pub fn born_lps(filters: Json<LifepathFilters>) -> String {
    "write me".to_string()
}
