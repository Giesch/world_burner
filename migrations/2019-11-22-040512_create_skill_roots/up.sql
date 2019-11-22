CREATE TYPE stat_type AS ENUM ('will', 'perception', 'power', 'agility', 'speed', 'forte');

CREATE TABLE skill_roots (
  skill_id INTEGER NOT NULL REFERENCES skills (id),

  -- there are three allowed states:
  -- just the first stat root
  -- two different stat roots, no attribute root
  -- just an attribute root (eg Greed, Grief, etc)
  first_stat_root stat_type,
  second_stat_root stat_type,
  attribute_root TEXT,

  CONSTRAINT skill_roots_attr_or_stat_check
  CHECK (
    (first_stat_root IS NOT NULL AND attribute_root IS NULL) OR
    (attribute_root IS NOT NULL AND first_stat_root IS NULL AND second_stat_root IS NULL)
  ),

  CONSTRAINT skill_roots_unique_stat_check
  CHECK (first_stat_root != second_stat_root),

  PRIMARY KEY (skill_id)
);

SELECT diesel_manage_updated_at('skill_roots');
