CREATE TABLE books (
  id SERIAL PRIMARY KEY,
  abbrev TEXT UNIQUE NOT NULL,
  title TEXT UNIQUE NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('books');
