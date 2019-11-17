CREATE TABLE books (
  id SERIAL PRIMARY KEY,
  title TEXT UNIQUE NOT NULL,
  abbreviation TEXT UNIQUE NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('books');
