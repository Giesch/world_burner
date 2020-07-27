CREATE TABLE lifepath_reqs (
  lifepath_id INTEGER NOT NULL REFERENCES lifepaths (id),
  predicate jsonb NOT NULL,
  description TEXT NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  PRIMARY KEY (lifepath_id)
);

SELECT diesel_manage_updated_at('lifepath_reqs');
