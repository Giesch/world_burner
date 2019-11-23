CREATE TYPE trait_type AS ENUM ('die', 'call_on', 'char');

CREATE TABLE traits (
  id SERIAL PRIMARY KEY,
  book book_type NOT NULL,

  -- char traits (only) are allowed to not have a page
  page INTEGER CHECK (page > 0),
  name TEXT UNIQUE NOT NULL,
  cost INTEGER, -- null means the trait is lifepath-only
  typ trait_type NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT non_char_must_have_page
  CHECK (typ = 'char' OR page IS NOT NULL)
);

SELECT diesel_manage_updated_at('traits');
