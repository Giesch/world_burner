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

pub mod routes;
pub mod schema;
pub mod seeding;

use routes::*;

pub fn app() -> rocket::Rocket {
    let routes = routes![spa::index, spa::route, spa::js];

    rocket::ignite().mount("/", routes)
}
