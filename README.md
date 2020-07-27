# world burner

a crud app that's in rust for some reason

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
