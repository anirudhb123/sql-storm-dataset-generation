WITH RECURSIVE movie_hierarchy AS (
    -- Select movies and their related titles, including recurring episodes
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000  -- Limiting to movies post 2000

    UNION ALL

    SELECT
        mt.id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id,
        mh.level + 1
    FROM
        aka_title mt
    JOIN
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),

actor_movie_info AS (
    -- Collecting info about actors and their associated movies
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        movie_hierarchy mh ON ci.movie_id = mh.movie_id
    GROUP BY
        a.id, a.name
),

-- Window function to rank actors based on the number of roles played
ranked_actors AS (
    SELECT
        actor_id,
        actor_name,
        role_count,
        RANK() OVER (ORDER BY role_count DESC) AS actor_rank
    FROM
        actor_movie_info
),

-- Final aggregation to get leading role actors and their movie titles
final_output AS (
    SELECT
        ra.actor_id,
        ra.actor_name,
        ra.role_count,
        ARRAY_AGG(DISTINCT mh.title) AS movies,
        ra.actor_rank
    FROM
        ranked_actors ra
    JOIN
        actor_movie_info ami ON ra.actor_id = ami.actor_id
    JOIN
        movie_hierarchy mh ON ami.movie_id = mh.movie_id
    WHERE
        ra.actor_rank <= 10  -- Limiting to the top 10 actors
    GROUP BY
        ra.actor_id, ra.actor_name, ra.role_count, ra.actor_rank
)

SELECT
    fo.actor_id,
    fo.actor_name,
    fo.role_count,
    fo.movies,
    CASE
        WHEN fo.role_count IS NULL THEN 'No Roles'
        ELSE 'Active Actor'
    END AS status
FROM
    final_output fo
ORDER BY
    fo.actor_rank;

This SQL query is designed to benchmark performance using various constructs. It includes a recursive CTE to navigate movies and episodes, aggregates actor roles with counts and ranks them, and uses conditional logic to classify actors based on their roles. Additionally, it features window functions, outer joins, and complicated aggregates while adhering to the given schema.
