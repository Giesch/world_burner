use super::errors::*;
use crate::db::DbConn;
use crate::services::lifepaths::*;
use rocket_contrib::json::Json;

#[post("/api/lifepaths/search", format = "json", data = "<filters>")]
pub fn list(db: DbConn, filters: Json<LifepathFilters>) -> RouteResult<Json<LifepathsResponse>> {
    let lifepaths = Lifepaths::list(db, &filters.into_inner())?;
    Ok(Json(LifepathsResponse { lifepaths }))
}

#[derive(Deserialize, Serialize, Debug)]
pub struct LifepathFilters {
    #[serde(default)]
    pub born: Option<bool>,

    #[serde(default)]
    pub setting_ids: Option<Vec<i32>>,

    #[serde(default)]
    pub search_term: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LifepathsResponse {
    pub lifepaths: Vec<Lifepath>,
}

impl From<LifepathsError> for RouteError {
    fn from(error: LifepathsError) -> Self {
        match error {
            LifepathsError::Useless => RouteError::useless(),
            LifepathsError::MissingValue(_msg) => RouteError::useless(),
        }
    }
}
