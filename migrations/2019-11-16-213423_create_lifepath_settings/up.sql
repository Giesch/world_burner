CREATE TABLE lifepath_settings (
  id SERIAL PRIMARY KEY,
  book_id INTEGER NOT NULL REFERENCES books (id),
  stock_id INTEGER NOT NULL REFERENCES stocks (id),
  page_number INTEGER NOT NULL CHECK (page_number > 0),
  name TEXT NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('lifepath_settings');
