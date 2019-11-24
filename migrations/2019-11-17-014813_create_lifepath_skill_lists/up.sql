CREATE TABLE lifepath_skill_lists (
  lifepath_id INTEGER NOT NULL REFERENCES lifepaths (id),
  list_position INTEGER NOT NULL CHECK (list_position >= 0),

  -- either a skill/wise with its own entry
  -- or a knowledge skill pointing to its general entry (e.g. wise, history)
  skill_id INTEGER NOT NULL REFERENCES skills (id),
  entryless_skill TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  PRIMARY KEY (lifepath_id, list_position)
);

SELECT diesel_manage_updated_at('lifepath_skill_lists');
