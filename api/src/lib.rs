#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use]
extern crate diesel;

#[macro_use]
extern crate diesel_derive_enum;

#[macro_use]
extern crate serde_derive;

#[macro_use]
extern crate rocket;

#[macro_use]
extern crate rocket_contrib;

pub mod db;
pub mod models;
pub mod repos;
pub mod routes;
pub mod schema;
pub mod seeding;

use db::DbConn;
use routes::*;

pub fn app() -> rocket::Rocket {
    let routes = routes![spa::index, spa::route, spa::js, lifepaths::born];

    rocket::ignite()
        .attach(DbConn::fairing())
        .mount("/", routes)
}
