SELECT * FROM skills LIMIT 25;

SELECT * FROM lifepaths LIMIT 10;

SELECT name,
       years,
       gen_skill_pts,
       skill_pts,
       trait_pts,
       stat_mod,
       stat_mod_val,
       res
  FROM lifepaths
 LIMIT 10;

SELECT * FROM lifepath_skill_lists;

SELECT * FROM lifepath_skill_lists WHERE lifepath_id = 28;

SELECT id,
       name,
       years,
       gen_skill_pts,
       skill_pts,
       trait_pts,
       stat_mod,
       stat_mod_val,
       res
  FROM lifepaths
 WHERE name
       IN (
            'born artificer',
            'ardent (artificer)',
            'tyro artificer',
            'adventurer'
        );

SELECT id,
       name,
       years,
       gen_skill_pts,
       skill_pts,
       trait_pts,
       stat_mod,
       stat_mod_val,
       res
  FROM lifepaths AS ls
 WHERE ls.born;

-- get the skill lists for a group of lifepaths
-- varargs are not supported in diesel .4
-- can use id.eq(any(vec![...]))
-- https://docs.diesel.rs/diesel/pg/expression/dsl/fn.any.html
-- https://docs.diesel.rs/diesel/expression_methods/trait.ExpressionMethods.html#method.eq_any
-- might need to just coalesce in memory
  SELECT COALESCE(
            l.entryless_skill,
            s.name
         ) AS display_name,
         l.skill_id,
         s.page,
         s.magical,
         s.training,
         s.wise,
         l.lifepath_id
    FROM lifepath_skill_lists AS l, skills AS s
   WHERE l.skill_id = s.id
     AND l.lifepath_id IN (29, 30, 31, 37)
ORDER BY lifepath_id, list_position;

-- get the leads for a group of lifepaths
  SELECT l.lifepath_id, l.setting_id, s.name, s.page
    FROM leads AS l, lifepath_settings AS s
   WHERE l.setting_id = s.id
     AND l.lifepath_id IN (29, 30, 31, 37)
ORDER BY l.lifepath_id;
