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
pub mod repos;
pub mod routes;
pub mod schema;
pub mod seeding;
pub mod services;

use db::DbConn;
use dotenv::dotenv;
use rocket::config::{Config, Environment, Value};
use routes::*;
use std::collections::HashMap;
use std::env;

pub fn app() -> rocket::Rocket {
    mount(rocket::ignite())
}

pub fn test_app() -> rocket::Rocket {
    mount(rocket::custom(test_config()))
}

fn mount(rocket: rocket::Rocket) -> rocket::Rocket {
    rocket.attach(DbConn::fairing()).mount("/", routes())
}

fn routes() -> Vec<rocket::Route> {
    routes![
        spa::index,
        spa::route,
        spa::elm_js,
        spa::draggable_js,
        lifepaths::list
    ]
}

fn test_config() -> Config {
    dotenv().expect("use dotenv");

    let local_url = env::var("LOCAL_DATABASE_URL").expect("get db url");
    let db_name = env::var("TEST_DATABASE_NAME").expect("get test db name");
    let url = format!("{}/{}", local_url, db_name);

    let mut db_config = HashMap::new();
    db_config.insert("url", url);

    let mut databases = HashMap::new();
    databases.insert("postgres_db", Value::from(db_config));

    Config::build(Environment::Development)
        .extra("databases", databases)
        .finalize()
        .unwrap()
}
