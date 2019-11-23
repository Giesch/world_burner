CREATE TABLE skill_forks (
  skill_id INTEGER NOT NULL REFERENCES skills (id),
  fork_id INTEGER NOT NULL REFERENCES skills (id),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  PRIMARY KEY (skill_id, fork_id)
);

SELECT diesel_manage_updated_at('skill_forks');
