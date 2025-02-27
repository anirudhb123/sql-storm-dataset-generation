WITH RECURSIVE actor_hierarchy AS (
    SELECT ci.person_id,
           1 AS level,
           t.id AS movie_id,
           t.title AS movie_title,
           a.name AS actor_name,
           CASE WHEN ci.note IS NULL THEN 'Standard Role' ELSE ci.note END as role_note
    FROM cast_info ci
    INNER JOIN aka_name a ON ci.person_id = a.person_id
    INNER JOIN aka_title t ON ci.movie_id = t.movie_id
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT ah.person_id,
           ah.level + 1,
           t.id AS movie_id,
           t.title AS movie_title,
           a.name AS actor_name,
           'Cameo Appearance' as role_note
    FROM actor_hierarchy ah
    INNER JOIN cast_info ci ON ci.movie_id = ah.movie_id
    INNER JOIN aka_name a ON ci.person_id = a.person_id
    INNER JOIN aka_title t ON ci.movie_id = t.movie_id
    WHERE ah.level < 5 AND t.production_year < 2010
)
SELECT a.actor_name,
       COUNT(DISTINCT ah.movie_id) AS total_movies,
       MAX(CASE WHEN ah.level = 1 THEN ah.role_note END) AS primary_role,
       STRING_AGG(DISTINCT ah.movie_title, '; ') AS movie_titles,
       AVG(EXTRACT(YEAR FROM CURRENT_DATE) - t.production_year) AS avg_years_since_release
FROM actor_hierarchy ah
INNER JOIN aka_name a ON ah.person_id = a.person_id
INNER JOIN aka_title t ON ah.movie_id = t.id
GROUP BY a.actor_name
HAVING COUNT(DISTINCT ah.movie_id) > 2
ORDER BY avg_years_since_release DESC
LIMIT 10;

-- A separate set operation to identify actors who were never in a successful film
SELECT a.actor_name
FROM aka_name a
LEFT JOIN (
    SELECT DISTINCT ci.person_id
    FROM cast_info ci
    INNER JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year >= 2015 AND t.id IN (
        SELECT movie_id
        FROM movie_info
        WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice') 
        AND info::numeric > 1000000
    )
) successful_actors ON a.person_id = successful_actors.person_id
WHERE successful_actors.person_id IS NULL
ORDER BY a.actor_name;

-- Combining results from two queries to produce a comprehensive report
SELECT actor_report.actor_name,
       actor_report.total_movies,
       less_successful_actors.actor_name AS never_successful_actor
FROM (
    -- The first query for successful actors
    WITH RECURSIVE actor_hierarchy AS (
        ...
        -- Same CTE from above
    )
    SELECT a.actor_name,
           COUNT(DISTINCT ah.movie_id) AS total_movies
    ...
) actor_report
FULL OUTER JOIN (
    -- The second query for never successful actors
    SELECT a.actor_name
    FROM aka_name a
    LEFT JOIN (
        ...
        -- Same logic as above
    ) successful_actors ON a.person_id = successful_actors.person_id
    WHERE successful_actors.person_id IS NULL
) less_successful_actors ON actor_report.actor_name = less_successful_actors.actor_name
ORDER BY actor_report.total_movies DESC, less_successful_actors.actor_name;
