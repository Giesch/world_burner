#[macro_use]
extern crate diesel;

#[macro_use]
extern crate diesel_derive_enum;

#[macro_use]
extern crate serde_derive;

pub mod schema;
pub mod seeding;

pub fn app() {
    println!("Hello, world!");
}
