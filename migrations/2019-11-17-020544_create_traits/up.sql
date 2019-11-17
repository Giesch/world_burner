CREATE TABLE traits (
  id SERIAL PRIMARY KEY,
  book_id INTEGER NOT NULL REFERENCES books (id),
  page_number INTEGER NOT NULL CHECK (page_number > 0),
  name TEXT NOT NULL,
  cost INTEGER, -- null means the trait is lifepath-only

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('traits');
