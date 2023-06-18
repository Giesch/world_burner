# world burner

This was a learning project I used for getting more familiarity with Rust and Elm. It implements the character creation rules for a tabletop RPG called Burning Wheel (players use 'burn' as a synonym for 'create'). I only ever got around to adding the Dwarf lifepaths. If you're not an RPG person, the main interesting thing would be that it involves serializable predicates (ie, 'Job A depends on either Job B or Jobs C and D being complete', but that's an editable rule in the database).

Because this depends on Rocket 4 and removed nightly features, getting it to build again would problably mean moving to a different web framework. Lesson learned there.

## requires  
  rust (nightly)  
  postgres  
  diesel_cli  
  
## setup 

set up dotenv file:  
cp .env.example .env

to set up db (http://diesel.rs/guides/getting-started/)
cargo install diesel_cli  
diesel setup

to build frontend:  
cd web  
./make_dev.sh

to run dev server:  
cargo run --bin seed  
cargo run

to run tests:  
cargo run --bin reset_test_db  
cargo test  
(or ./integration_test.sh)
