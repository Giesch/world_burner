CREATE TABLE stocks (
  id SERIAL PRIMARY KEY,
  book_id INTEGER NOT NULL REFERENCES books (id),
  name TEXT NOT NULL,
  singular TEXT NOT NULL,
  page INTEGER NOT NULL CHECK (page > 0),

  UNIQUE (book_id, name),
  UNIQUE (book_id, singular),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('stocks');
