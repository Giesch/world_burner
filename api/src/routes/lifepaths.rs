use super::errors::*;
use crate::db::DbConn;
use crate::models::lifepaths::*;
use rocket_contrib::json::Json;

#[get("/api/lifepaths/born", format = "json")]
pub fn born(db: DbConn) -> Result<Json<LifepathsResponse>, Error> {
    let lifepaths = Lifepaths::born(db)?;
    Ok(Json(LifepathsResponse { lifepaths }))
}

#[derive(Debug, Serialize)]
pub struct LifepathsResponse {
    lifepaths: Vec<Lifepath>,
}

impl From<LifepathsError> for Error {
    fn from(error: LifepathsError) -> Self {
        match error {
            LifepathsError::Useless => Error::ServerError(Json(ErrorResponse::useless())),
        }
    }
}
