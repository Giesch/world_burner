CREATE TYPE tool_req AS ENUM ('yes', 'no', 'expendable', 'workshop');

CREATE TABLE skill_types (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO skill_types (name)
VALUES
  ('academic'),
  ('artisan'),
  ('artist'),
  ('craftsman'),
  ('forester'),
  ('martial'),
  ('medicinal'),
  ('military'),
  ('musical'),
  ('peasant'),
  ('physical'),
  ('school_of_thought'),
  ('seafaring'),
  ('social'),
  ('sorcerous'),
  ('special');

SELECT diesel_manage_updated_at('skill_types');

CREATE TABLE skills (
  id SERIAL PRIMARY KEY,
  skill_type_id INTEGER NOT NULL REFERENCES skill_types (id),
  book book_type NOT NULL,
  page INTEGER NOT NULL CHECK (page > 0),
  name TEXT NOT NULL,
  magical BOOLEAN NOT NULL DEFAULT false,
  training BOOLEAN NOT NULL DEFAULT false,
  wise BOOLEAN NOT NULL DEFAULT false,
  tools tool_req NOT NULL,

  UNIQUE (book, name),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('skills');
