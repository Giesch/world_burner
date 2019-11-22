CREATE TYPE stat_type AS ENUM ('will', 'perception', 'power', 'agility', 'speed', 'forte');

CREATE TABLE skill_roots (
  skill_id INTEGER NOT NULL REFERENCES skills (id),
  first_stat_root stat_type,
  second_stat_root stat_type,
  attribute_root TEXT,

  CHECK (
    (first_stat_root IS NOT NULL AND attribute_root IS NULL) OR
    (attribute_root IS NOT NULL AND first_stat_root IS NULL AND second_stat_root IS NULL)
  ),

  PRIMARY KEY (skill_id)
);

SELECT diesel_manage_updated_at('skill_roots');