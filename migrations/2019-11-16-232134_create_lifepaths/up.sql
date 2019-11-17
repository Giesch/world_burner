CREATE TABLE lifepaths (
  id SERIAL PRIMARY KEY,
  book_id INTEGER NOT NULL REFERENCES books (id),
  lifepath_setting_id INTEGER NOT NULL REFERENCES lifepath_settings (id),
  page_number INTEGER NOT NULL CHECK (page_number > 0),

  name TEXT NOT NULL,
  years INTEGER CHECK (years >= 0), -- null means choose (prince of the blood)
  skill_pts INTEGER NOT NULL CHECK (skill_pts >= 0),
  trait_pts INTEGER NOT NULL CHECK (trait_pts >= 0),

  physical_modifier INTEGER NOT NULL
    CHECK (physical_modifier >= -1 AND physical_modifier <= 2),
  mental_modifier INTEGER NOT NULL
    CHECK (mental_modifier >= -1 AND mental_modifier <= 2),
  optional_modifier INTEGER NOT NULL
    CHECK (optional_modifier >= -1 AND optional_modifier <= 2),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

SELECT diesel_manage_updated_at('lifepaths');
