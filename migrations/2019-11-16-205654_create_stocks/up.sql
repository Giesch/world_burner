CREATE TABLE stocks (
  id SERIAL PRIMARY KEY,
  book book_type NOT NULL,
  name TEXT NOT NULL,
  page INTEGER NOT NULL CHECK (page > 0),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('stocks');
