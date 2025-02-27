WITH RECURSIVE actor_hierarchy AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        1 AS lvl
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        t.production_year IS NOT NULL

    UNION ALL

    SELECT
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        lvl + 1
    FROM
        actor_hierarchy ah
    JOIN
        cast_info c ON ah.movie_id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        ah.lvl < 3 -- Limiting the hierarchy depth
)

SELECT
    ah.actor_name,
    COUNT(DISTINCT ah.movie_title) AS movies_count,
    STRING_AGG(DISTINCT ah.movie_title, ', ') AS movie_list,
    AVG(ah.production_year) AS average_production_year,
    MIN(ah.production_year) AS first_movie_year,
    MAX(ah.production_year) AS last_movie_year,
    MAX(ah.production_year) - MIN(ah.production_year) AS career_span
FROM
    actor_hierarchy ah
GROUP BY
    ah.actor_name
ORDER BY
    movies_count DESC
LIMIT 10;

-- This query generates an actor hierarchy from movies they've acted in, including their average production year,
-- the earliest and latest movie year they've participated in, and their career span based on the years of their movies.
-- It uses a recursive CTE to gather up to 3 levels of movies in which the actors were involved and aggregates the results.
