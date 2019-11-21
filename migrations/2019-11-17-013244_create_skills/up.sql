CREATE TYPE tool_req AS ENUM ('yes', 'no', 'expendable', 'workshop');

CREATE TABLE skills (
  id SERIAL PRIMARY KEY,
  book book_type NOT NULL,
  page INTEGER NOT NULL CHECK (page > 0),
  name TEXT NOT NULL,
  magical BOOLEAN NOT NULL DEFAULT false,
  wise BOOLEAN NOT NULL DEFAULT false,
  tools tool_req NOT NULL DEFAULT 'no',

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('skills');
