# world burner

a crud app that's in rust for some reason

## requires  
  rust (stable)  
  postgres  
  diesel_cli  
  
## setup 

cp .env.example .env

http://diesel.rs/guides/getting-started/

cargo install diesel_cli  
echo DATABASE_URL=postgres:postgres//localhost/world_burner > .env  
diesel setup

cargo run --bin seed
