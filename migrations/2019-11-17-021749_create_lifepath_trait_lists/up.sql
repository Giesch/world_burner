CREATE TABLE lifepath_trait_lists (
  lifepath_id INTEGER NOT NULL REFERENCES lifepaths (id),
  list_position INTEGER NOT NULL CHECK (list_position >= 0),
  trait_id INTEGER NOT NULL REFERENCES traits (id),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  PRIMARY KEY (lifepath_id, list_position, trait_id)
);

SELECT diesel_manage_updated_at('lifepath_trait_lists');
