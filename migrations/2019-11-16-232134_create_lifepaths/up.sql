CREATE TYPE stat_mod_type AS ENUM ('physical', 'mental', 'either', 'both');

CREATE TABLE lifepaths (
  id SERIAL PRIMARY KEY,
  book book_type NOT NULL,
  lifepath_setting_id INTEGER NOT NULL REFERENCES lifepath_settings (id),
  page INTEGER NOT NULL CHECK (page > 0),

  name TEXT NOT NULL,

  -- either a number, or a range (e.g. prince of the blood)
  years INTEGER CHECK (years >= 0),
  years_min INTEGER,
  years_max INTEGER,

  gen_skill_pts INTEGER NOT NULL CHECK (gen_skill_pts >= 0),
  skill_pts INTEGER NOT NULL CHECK (skill_pts >= 0),
  trait_pts INTEGER NOT NULL CHECK (trait_pts >= 0),

  -- either type and value are present, or neither are
  stat_mod stat_mod_type,
  stat_mod_val INTEGER CHECK (stat_mod_val IN (-1, 1, 2)),

  -- either a number, or a specified calculation (e.g. hostage)
  res INTEGER,
  res_calc TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- these are roll-your-own tagged unions
  -- https://hashrocket.com/blog/posts/modeling-polymorphic-associations-in-a-relational-database

  CONSTRAINT valid_res CHECK (
    (res IS NOT NULL)::INTEGER +
    (res_calc IS NOT NULL)::INTEGER = 1
  ),

  CONSTRAINT valid_stat_mod CHECK (
    (stat_mod IS NOT NULL AND stat_mod_val IS NOT NULL) OR
    (stat_mod IS NULL AND stat_mod_val IS NULL)
  ),

  CONSTRAINT valid_years CHECK (
    (years IS NOT NULL AND years_min IS NULL AND years_max IS NULL) OR
    (years IS NULL AND years_min IS NOT NULL AND years_max IS NOT NULL)
  ),

  CONSTRAINT valid_years_range CHECK (years_min < years_max)
);

SELECT diesel_manage_updated_at('lifepaths');
