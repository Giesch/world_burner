CREATE TABLE lifepath_trait_lists (
  lifepath_id INTEGER NOT NULL REFERENCES lifepaths (id),
  list_position INTEGER NOT NULL CHECK (list_position >= 0),

  -- either a trait (any type) with an entry, or a char trait without an entry
  trait_id INTEGER REFERENCES traits (id),
  char_trait TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT listed_trait_or_char_trait
  CHECK (
    (trait_id IS NOT NULL)::INTEGER +
    (char_trait IS NOT NULL)::INTEGER = 1
  ),

  PRIMARY KEY (lifepath_id, list_position)
);

SELECT diesel_manage_updated_at('lifepath_trait_lists');
