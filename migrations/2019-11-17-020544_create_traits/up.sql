CREATE TYPE trait_type AS ENUM ('die', 'call_on', 'char');

CREATE TABLE traits (
  id SERIAL PRIMARY KEY,
  book book_type NOT NULL,

  page INTEGER NOT NULL CHECK (page > 0),
  name TEXT UNIQUE NOT NULL,
  cost INTEGER, -- null means the trait is lifepath-only
  typ trait_type NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('traits');
