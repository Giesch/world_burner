//! Structured errors for bad requests based on json-api.

use rocket_contrib::json::Json;
use serde::Serialize;

#[derive(Debug, Responder)]
pub enum Error {
    #[response(status = 400)]
    BadRequest(Json<ErrorResponse>),

    #[response(status = 500)]
    ServerError(Json<ErrorResponse>),
}

#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub errors: Vec<ErrorObject>,
}

impl ErrorResponse {
    pub fn useless() -> Self {
        ErrorResponse {
            errors: vec![ErrorObject::useless()],
        }
    }

    pub fn useful() -> Builder {
        Builder
    }
}

pub struct Builder;

impl Builder {
    pub fn title(title: String) -> BuilderWithTitle {
        BuilderWithTitle { title }
    }
}

pub struct BuilderWithTitle {
    title: String,
}

impl BuilderWithTitle {
    pub fn detail(self, detail: String) -> BuilderWithDetail {
        BuilderWithDetail {
            title: self.title,
            detail,
        }
    }
}

pub struct BuilderWithDetail {
    title: String,
    detail: String,
}

impl BuilderWithDetail {
    pub fn source(self, source: String) -> ErrorResponse {
        ErrorResponse {
            errors: vec![ErrorObject::useful(self.title, self.detail, source)],
        }
    }
}

#[derive(Debug, Serialize)]
#[serde(untagged)]
pub enum ErrorObject {
    UsefulError {
        title: String,
        detail: String,
        source: ErrorSource,
    },

    UselessError {
        title: String,
        detail: String,
    },
}

#[derive(Debug, Serialize)]
pub struct ErrorSource {
    pointer: String,
}

impl ErrorObject {
    pub fn useful(title: String, detail: String, pointer: String) -> ErrorObject {
        ErrorObject::UsefulError {
            title,
            detail,
            source: ErrorSource { pointer },
        }
    }

    pub fn useless() -> ErrorObject {
        ErrorObject::UselessError {
            title: "Unknown Error".into(),
            detail: "An unknown error ocurred".into(),
        }
    }
}
