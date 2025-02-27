WITH RECURSIVE actor_hierarchy AS (
    -- Recursive CTE to build a hierarchy of actors and their co-actors
    SELECT
        c1.person_id AS actor_id,
        c1.movie_id,
        1 AS depth
    FROM
        cast_info c1
    UNION ALL
    SELECT
        c2.person_id,
        c2.movie_id,
        a.depth + 1
    FROM
        cast_info c2
    INNER JOIN actor_hierarchy a ON c2.movie_id = a.movie_id
    WHERE
        c2.person_id <> a.actor_id
),
movie_year_info AS (
    -- CTE to get the movie titles and their production years
    SELECT
        t.title,
        t.production_year,
        t.id AS movie_id
    FROM
        title t
),
actor_details AS (
    -- CTE to gather actor names and their roles
    SELECT
        a.name AS actor_name,
        c.role_id,
        m.production_year,
        a.id AS person_id
    FROM
        aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN movie_year_info m ON c.movie_id = m.movie_id
),
ranked_actors AS (
    -- Use window functions to rank actors by the number of movies they have been in
    SELECT
        actor_name,
        COUNT(*) AS movie_count,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS actor_rank
    FROM
        actor_details
    GROUP BY
        actor_name
),
co_actor_summary AS (
    -- Summarize the results from the actor hierarchy
    SELECT
        ah.actor_id,
        COUNT(DISTINCT ah.movie_id) AS co_star_count
    FROM
        actor_hierarchy ah
    GROUP BY
        ah.actor_id
)
SELECT
    ra.actor_name,
    ra.movie_count,
    CASE 
        WHEN co.co_star_count IS NOT NULL THEN co.co_star_count 
        ELSE 0 
    END AS co_star_count,
    CASE 
        WHEN ra.movie_count > 10 THEN 'Prolific Actor'
        ELSE 'Novice'
    END AS classification
FROM
    ranked_actors ra
LEFT JOIN co_actor_summary co ON ra.person_id = co.actor_id
WHERE
    ra.actor_rank <= 10
ORDER BY
    ra.movie_count DESC, ra.actor_name;

This SQL query includes:
- Recursive CTEs to explore the relationships between actors (actor_hierarchy).
- A specific CTE for gathering movie titles and production years (movie_year_info).
- An actor details CTE that joins actor names with their roles and production years (actor_details).
- Window functions to rank actors based on the number of movies they have appeared in (ranked_actors).
- Co-star count aggregated by counting distinct movies (co_actor_summary).
- Conditional expressions to classify actors based on their experience.
- A `LEFT JOIN` to keep track of actors without co-stars.
- A final selection that displays top 10 actors based on their movie count while handling NULL values appropriately.
