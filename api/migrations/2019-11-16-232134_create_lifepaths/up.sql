CREATE TYPE stat_mod_type AS ENUM ('physical', 'mental', 'either', 'both');

CREATE TYPE res_calc_type AS ENUM ('half_previous', 'ten_per_year');

CREATE TYPE gen_skill_calc_type AS ENUM ('one_per_year');

CREATE TABLE lifepaths (
  id SERIAL PRIMARY KEY,
  book_id INTEGER NOT NULL REFERENCES books (id),
  lifepath_setting_id INTEGER NOT NULL REFERENCES lifepath_settings (id),
  page INTEGER NOT NULL
    CONSTRAINT lifepaths_positive_page
    CHECK (page > 0),

  name TEXT NOT NULL,

  born BOOLEAN NOT NULL DEFAULT FALSE,

  -- either a number, or a range (e.g. prince of the blood)
  years INTEGER
    CONSTRAINT positive_years
    CHECK (years >= 0),
  years_min INTEGER,
  years_max INTEGER,

  gen_skill_pts INTEGER
    CONSTRAINT positive_gen_skill_pts
    CHECK (gen_skill_pts >= 0),
  gen_skill_pts_calc gen_skill_calc_type,

  skill_pts INTEGER NOT NULL
    CONSTRAINT positive_skill_pts
    CHECK (skill_pts >= 0),
  trait_pts INTEGER NOT NULL
    CONSTRAINT positive_trait_pts
    CHECK (trait_pts >= 0),

  -- either type and value are present, or neither are
  stat_mod stat_mod_type,
  stat_mod_val INTEGER
    CONSTRAINT valid_stat_mod_val
    CHECK (stat_mod_val IN (-1, 1, 2)),

  -- either a number, or a specified calculation (e.g. hostage)
  res INTEGER,
  res_calc res_calc_type,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (lifepath_setting_id, name),

  CONSTRAINT lifepaths_gen_skills_or_calc_check CHECK (
    (gen_skill_pts IS NOT NULL)::INTEGER +
    (gen_skill_pts_calc IS NOT NULL)::INTEGER = 1
  ),

  CONSTRAINT lifepaths_res_or_res_calc_check CHECK (
    (res IS NOT NULL)::INTEGER +
    (res_calc IS NOT NULL)::INTEGER = 1
  ),

  CONSTRAINT lifepaths_stat_mod_and_stat_mod_val_check CHECK (
    (stat_mod IS NOT NULL AND stat_mod_val IS NOT NULL) OR
    (stat_mod IS NULL AND stat_mod_val IS NULL)
  ),

  CONSTRAINT lifepaths_years_or_years_range_check CHECK (
    (years IS NOT NULL AND years_min IS NULL AND years_max IS NULL) OR
    (years IS NULL AND years_min IS NOT NULL AND years_max IS NOT NULL)
  ),

  CONSTRAINT lifepaths_valid_years_range_check CHECK (years_min < years_max)
);

SELECT diesel_manage_updated_at('lifepaths');
