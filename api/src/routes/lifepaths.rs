use crate::db::DbConn;
use crate::models::lifepaths::*;
use rocket_contrib::json::Json;

#[derive(Debug, Serialize)]
pub struct LifepathsResponse {
    lifepaths: Vec<Lifepath>,
}

#[derive(Debug, Serialize)]
pub struct RoutesError {
    error: String,
}

impl From<LifepathsError> for RoutesError {
    fn from(_err: LifepathsError) -> Self {
        RoutesError {
            error: "oops".to_string(),
        }
    }
}

#[get("/lifepaths/born", format = "json")]
pub fn born(db: DbConn) -> Result<Json<LifepathsResponse>, RoutesError> {
    let lifepaths = Lifepaths::born(db)?;
    let response = LifepathsResponse { lifepaths };

    Ok(Json(response))
}
