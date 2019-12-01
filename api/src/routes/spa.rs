use rocket::http::uri;
use rocket::response::NamedFile;
use std::path::Path;

const INDEX_HTML_PATH: &str = "../web/index.html";
const ELM_JS_PATH: &str = "../web/elm.js";

#[get("/")]
pub fn index() -> Option<NamedFile> {
    NamedFile::open(Path::new(INDEX_HTML_PATH)).ok()
}

#[get("/<_route..>")]
pub fn route(_route: uri::Segments) -> Option<NamedFile> {
    NamedFile::open(Path::new(INDEX_HTML_PATH)).ok()
}

#[get("/elm.js")]
pub fn js() -> Option<NamedFile> {
    NamedFile::open(Path::new(ELM_JS_PATH)).ok()
}
