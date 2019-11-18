CREATE TYPE book_type AS ENUM ('gold_revised', 'codex');

CREATE TABLE books (
  book book_type PRIMARY KEY,
  abbrev TEXT UNIQUE NOT NULL,
  title TEXT UNIQUE NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('books');
