# world burner

This was a learning project I used for getting more familiarity with Rust and Elm. It implements the character creation rules for a tabletop RPG called Burning Wheel (players use 'burn' as a synonym for 'create'). I only ever got around to adding the Dwarf lifepaths.

If you're not an RPG person, the main interesting thing would be that it involves serializable predicates (ie, 'Job A depends on either Job B or both of Jobs C and D being complete', but that's an editable rule in the database). On the Elm side, it includes a custom implementation of drag-and-drop inspired by NoRedInk's blog post encouraging that.

## setup 

Because this is an old project that depends on Rocket 4 and removed nightly features, the backend setup is a little involved.

### dependencies

- an old rust nightly  
  (a compatible version is in rustfmt.toml)
- elm 19:  
  https://guide.elm-lang.org/install/elm.html
- postgres 
``` sh
sudo apt install postgresql postgresql-contrib libpq-dev # libpq is needed by diesel_cli
sudo systemctl start postgresql
sudo systemctl enable postgresql # optionally enable starting postgres on boot
```

### to set up db (http://diesel.rs/guides/getting-started/)

from a different directory (with a more recent rust toolchain):  
``` sh
cargo install diesel_cli --no-default-features --features postgres --version 1.4.1
```

back in this directory:  
``` sh
cp .env.example .env
diesel setup
cargo run --bin seed
```

build the frontend:  
``` sh
cd web && ./make_dev.sh && cd -
```

run the server:  
``` sh
cargo run
```

run tests:  
``` sh
./integration_test.sh
```
