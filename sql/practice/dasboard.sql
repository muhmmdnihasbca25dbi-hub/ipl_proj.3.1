-- SQL query reference copied from dashboard/app.py.
-- The `{season_sql}` and `{margin_season_sql}` tokens are generated in Python
-- by season_clause(); replace each token with its returned SQL predicate.
-- The `?` placeholders are bound by pandas/SQLite using the accompanying params.

-- Overview: available seasons
SELECT DISTINCT season_year
FROM matches_clean
WHERE season_year IS NOT NULL
ORDER BY season_year;

-- Overview: competition scale
SELECT COUNT(*) AS matches,
       COUNT(DISTINCT season_year) AS seasons
FROM matches_clean;

-- Overview: total runs
SELECT COALESCE(SUM(runs), 0) AS total_runs
FROM v_innings;

-- Overview: chase statistics for the selected seasons
SELECT SUM(mt.chase_won) AS chase_wins,
       COUNT(*) AS n,
       100.0 * SUM(mt.chase_won) / NULLIF(COUNT(*), 0) AS chase_rate,
       100.0 * wilson_low(SUM(mt.chase_won), COUNT(*)) AS ci_low,
       100.0 * wilson_high(SUM(mt.chase_won), COUNT(*)) AS ci_high,
       binom_pvalue(SUM(mt.chase_won), COUNT(*), 0.5) AS p_value
FROM v_match_totals mt
JOIN matches_clean m ON m.match_id = mt.match_id
WHERE {season_sql};

-- Overview: average innings score by selected season
SELECT m.season_year,
       AVG(i.runs) AS avg_score,
       COUNT(DISTINCT m.match_id) AS match_count
FROM matches_clean m
JOIN v_innings i ON i.match_id = m.match_id
WHERE {season_sql}
GROUP BY m.season_year
ORDER BY m.season_year;

-- Overview: league average innings score for selected seasons
SELECT AVG(i.runs) AS league_avg
FROM matches_clean m
JOIN v_innings i ON i.match_id = m.match_id
WHERE {season_sql};

-- Overview: chase win rate by first-innings target band
SELECT CASE
           WHEN mt.first_innings_runs < 140 THEN '<140'
           WHEN mt.first_innings_runs < 170 THEN '140–169'
           WHEN mt.first_innings_runs < 200 THEN '170–199'
           ELSE '200+'
       END AS target_band,
       SUM(mt.chase_won) AS chase_wins,
       COUNT(*) AS match_count,
       100.0 * SUM(mt.chase_won) / NULLIF(COUNT(*), 0) AS chase_rate
FROM v_match_totals mt
JOIN matches_clean m ON m.match_id = mt.match_id
WHERE {season_sql}
GROUP BY target_band
ORDER BY CASE target_band
           WHEN '<140' THEN 1
           WHEN '140–169' THEN 2
           WHEN '170–199' THEN 3
           ELSE 4
         END;

-- Overview: sixes by season
SELECT m.season_year,
       SUM(CASE WHEN d.batter_runs = 6 THEN 1 ELSE 0 END) AS sixes,
       COUNT(DISTINCT m.match_id) AS match_count
FROM deliveries d
JOIN matches_clean m ON m.match_id = d.match_id
WHERE d.is_super_over = 0 AND {season_sql}
GROUP BY m.season_year
ORDER BY m.season_year;

-- Overview: wins by margin type
SELECT CASE
         WHEN c.result = 'win' AND m.win_by_runs > 0 THEN 'Wins by runs'
         WHEN c.result = 'win' AND m.win_by_wickets > 0 THEN 'Wins by wickets'
       END AS margin_type,
       COUNT(*) AS match_count
FROM matches_clean c
JOIN matches m ON m.match_id = c.match_id
WHERE {margin_season_sql} AND c.result = 'win'
GROUP BY margin_type
ORDER BY margin_type;

-- Overview: toss decision by season
SELECT m.season_year,
       m.toss_decision,
       COUNT(*) AS match_count
FROM matches_clean m
WHERE {season_sql}
GROUP BY m.season_year, m.toss_decision
ORDER BY m.season_year, m.toss_decision;

-- Match detail: available seasons
SELECT DISTINCT season_year
FROM matches_clean
ORDER BY season_year;

-- Match detail: available teams
SELECT DISTINCT team
FROM (
    SELECT team1 AS team FROM matches_clean
    UNION
    SELECT team2 AS team FROM matches_clean
)
WHERE team IS NOT NULL
  AND TRIM(team) <> ''
ORDER BY team;

-- Match detail: matches in the selected season when all teams are selected
SELECT match_id, season_year, team1, team2, venue_clean, city_clean
FROM matches_clean
WHERE season_year = ?
ORDER BY match_id;

-- Match detail: matches in the selected season for one selected team
SELECT match_id, season_year, team1, team2, venue_clean, city_clean
FROM matches_clean
WHERE season_year = ?
  AND (team1 = ? OR team2 = ?)
ORDER BY match_id;

-- Match detail: selected match information
SELECT c.match_id,
       c.season_year,
       c.venue_clean,
       c.city_clean,
       c.team1,
       c.team2,
       c.result,
       c.match_winner,
       c.player_of_match,
       c.toss_winner,
       c.toss_decision,
       m.win_by_runs,
       m.win_by_wickets
FROM matches_clean c
JOIN matches m ON m.match_id = c.match_id
WHERE c.match_id = ?;

-- Match detail: innings summary for the selected match
SELECT innings, batting_team, runs, wickets, legal_balls
FROM v_innings
WHERE match_id = ?
ORDER BY innings;

-- Match detail: runs per over for both innings
SELECT innings,
       over_number + 1 AS over_number,
       SUM(total_runs) AS runs
FROM v_ball
WHERE match_id = ?
  AND innings IN (1, 2)
GROUP BY innings, over_number
ORDER BY innings, over_number;

-- Match detail: fours and sixes by innings
SELECT innings,
       SUM(CASE WHEN batter_runs = 4 THEN 1 ELSE 0 END) AS fours,
       SUM(CASE WHEN batter_runs = 6 THEN 1 ELSE 0 END) AS sixes,
       COUNT(*) AS balls
FROM v_ball
WHERE match_id = ?
  AND innings IN (1, 2)
GROUP BY innings
ORDER BY innings;

-- Match detail: top run scorers in the selected match
SELECT batter,
       SUM(batter_runs) AS runs,
       SUM(CASE WHEN is_legal = 1 THEN 1 ELSE 0 END) AS legal_balls
FROM v_ball
WHERE match_id = ?
GROUP BY batter
ORDER BY runs DESC, legal_balls DESC
LIMIT 5;

-- Match detail: top wicket takers in the selected match
SELECT bowler,
       SUM(bowler_wicket) AS wickets,
       SUM(is_legal) AS legal_balls,
       SUM(bowler_runs) AS runs_conceded
FROM v_ball
WHERE match_id = ?
GROUP BY bowler
ORDER BY wickets DESC, runs_conceded ASC
LIMIT 5;

-- Match detail: runs and wickets by phase for the selected match
SELECT innings,
       phase,
       SUM(total_runs) AS runs,
       SUM(is_wicket) AS wickets,
       SUM(is_legal) AS legal_balls
FROM v_ball
WHERE match_id = ?
  AND innings IN (1, 2)
GROUP BY innings, phase
ORDER BY innings,
         CASE phase WHEN 'Powerplay' THEN 1 WHEN 'Middle' THEN 2 ELSE 3 END;

-- Match detail: bowler-credited wickets by over
SELECT innings,
       over_number + 1 AS over_number,
       SUM(bowler_wicket) AS wickets
FROM v_ball
WHERE match_id = ?
  AND innings IN (1, 2)
GROUP BY innings, over_number
HAVING SUM(bowler_wicket) > 0
ORDER BY innings, over_number;