-- sql/08_matches_clean.sql

DROP TABLE IF EXISTS matches_clean;     -- so a second run works
CREATE TABLE matches_clean AS           -- store the answer
SELECT m.match_id,                      -- the key
       m.venue_clean,                   -- from Fix 3
       c.city_clean,                    -- from Fix 5
       s.season_year,                   -- from Fix 6
       m.result,                        -- for the win rule
       m.match_winner,                  -- unchanged
       m.player_of_match,              -- unchanged
       m.toss_decision                  -- unchanged
FROM   v_matches_venue m                -- 1212 rows
JOIN   v_city_clean c ON c.match_id = m.match_id
JOIN   v_season     s ON s.match_id = m.match_id;