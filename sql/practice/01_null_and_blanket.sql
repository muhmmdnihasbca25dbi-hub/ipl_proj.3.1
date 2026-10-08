--deliveries.bowler_type
--players.field_pos
--matches.player_of_match
--contains fix 1,2,3



DROP VIEW IF EXISTS _deliveries_clean;      -- so a second run works
CREATE VIEW _deliveries_clean AS            -- name the rule
SELECT *,                                   -- keep every column
         NULLIF (TRIM (bowler_type), '') AS bowler_type_clean 
FROM     deliveries;                        -- read the raw table

DROP VIEW IF EXISTS _players_clean;         -- same shape again
CREATE VIEW _players_clean AS
SELECT *,
        NULLIF(TRIM(field_pos), '') AS field_pos_clean
FROM players;

DROP VIEW IF EXISTS matches_pom;            -- and once more
CREATE VIEW matches_pom AS
SELECT *,
        NULLIF (TRIM(player_of_match), '') AS pom_clean
FROM matches;
