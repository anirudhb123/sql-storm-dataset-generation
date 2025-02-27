WITH RECURSIVE actor_hierarchy AS (
    SELECT ci.person_id, ci.movie_id, 1 AS level
    FROM cast_info ci
    WHERE ci.role_id IS NOT NULL

    UNION ALL

    SELECT ci.person_id, ci.movie_id, ah.level + 1
    FROM cast_info ci
    JOIN actor_hierarchy ah ON ci.movie_id = ah.movie_id
    WHERE ci.person_id <> ah.person_id
),
movie_cast_summary AS (
    SELECT 
        t.title,
        EXTRACT(YEAR FROM t.production_year) AS year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM aka_title t
    LEFT JOIN cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY t.title, t.production_year
),
high_actor_movies AS (
    SELECT title, year, actor_count, actor_names
    FROM movie_cast_summary
    WHERE actor_count > (
        SELECT AVG(actor_count)
        FROM movie_cast_summary
    )
),
recent_movies AS (
    SELECT DISTINCT m.title, m.year
    FROM high_actor_movies m
    WHERE m.year = (SELECT MAX(year) FROM high_actor_movies)
)
SELECT 
    r.title,
    r.year,
    r.actor_count,
    r.actor_names,
    CASE 
        WHEN r.actor_count IS NULL THEN 'No Actors'
        WHEN r.actor_count = 1 THEN 'Single Actor Movie'
        ELSE 'Multi Actor Movie' 
    END AS movie_type
FROM high_actor_movies r
RIGHT JOIN recent_movies rm ON r.title = rm.title
ORDER BY r.actor_count DESC NULLS LAST;
