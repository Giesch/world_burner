CREATE TABLE leads (
  lifepath_id INTEGER NOT NULL REFERENCES lifepaths (id),
  setting_id INTEGER NOT NULL REFERENCES lifepath_settings (id),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  PRIMARY KEY (lifepath_id, setting_id)
);

SELECT diesel_manage_updated_at('leads');
