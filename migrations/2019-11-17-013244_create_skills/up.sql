CREATE TYPE tool_req AS ENUM (
  'yes', 'no', 'expendable', 'workshop', 'weapon', 'traveling_gear'
);

CREATE TABLE skills (
  id SERIAL PRIMARY KEY,
  book_id INTEGER NOT NULL REFERENCES books (id),
  page INTEGER NOT NULL CHECK (page > 0),
  name TEXT NOT NULL,
  magical BOOLEAN NOT NULL DEFAULT false,
  training BOOLEAN NOT NULL DEFAULT false,
  wise BOOLEAN NOT NULL DEFAULT false,
  tools tool_req NOT NULL,

  UNIQUE (book_id, name),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('skills');
