use super::errors::*;
use crate::db::DbConn;
use crate::diesel::Connection;
use crate::services::lifepaths::*;
use rocket_contrib::json::Json;

#[get("/api/lifepaths/dwarves", format = "json")]
pub fn dwarves(db: DbConn) -> RouteResult<Json<LifepathsResponse>> {
    let lifepaths = (&*db).transaction(|| Lifepaths::list(&*db, &ALL_LIFEPATHS))?;
    Ok(Json(LifepathsResponse { lifepaths }))
}

pub const ALL_LIFEPATHS: LifepathFilters = LifepathFilters {
    born: None,
    setting_ids: None,
    search_term: None,
};

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
            LifepathsError::InvalidJson => RouteError::useless(),
        }
    }
}

impl From<diesel::result::Error> for LifepathsError {
    fn from(_error: diesel::result::Error) -> Self {
        LifepathsError::Useless
    }
}
