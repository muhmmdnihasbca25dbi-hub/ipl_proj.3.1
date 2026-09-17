--deliveries.bowler_type
--teams.team_name
--contains fix 4,5

--right arm medium fast and rising pune supergiants are
--merging in this fix
DROP VIEW IF EXISTS v_deliveries_typed;
CREATE VIEW v_deliveries_typed AS
SELECT *,
        CASE WHEN bowler_type_clean = 
                  'Right arm Fast Medium'
             THEN 'Right arm Fast medium'
             ELSE bowler_type_clean
        END AS bowler_style
FROM v_deliveries_clean;

DROP VIEW IF EXISTS v_teams_clean;
CREATE VIEW v_teams_clean AS
SELECT *,
        CASE WHEN team_name = 'Rising Pune Supergiants'
             THEN 'Rising Pune Supergiant'
             ELSE team_name
        END AS team_name_clean
FROM    teams;