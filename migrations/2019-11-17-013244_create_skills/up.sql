CREATE TYPE tool_req AS ENUM ('yes', 'no', 'workshop', 'weapon', 'traveling_gear');

CREATE TABLE skills (
  id SERIAL PRIMARY KEY,
  book_id INTEGER NOT NULL REFERENCES books (id),
  page INTEGER NOT NULL CHECK (page > 0),
  name TEXT NOT NULL,
  magical BOOLEAN NOT NULL DEFAULT FALSE,
  training BOOLEAN NOT NULL DEFAULT FALSE,
  wise BOOLEAN NOT NULL DEFAULT FALSE,
  tools tool_req NOT NULL,
  tools_expendable BOOLEAN NOT NULL DEFAULT FALSE,

  UNIQUE (book_id, name),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('skills');
