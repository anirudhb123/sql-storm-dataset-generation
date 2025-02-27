WITH movie_actor_counts AS (
    SELECT
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        a.person_id
),
top_actors AS (
    SELECT
        person_id
    FROM
        movie_actor_counts
    ORDER BY
        movie_count DESC
    LIMIT 10
),
actor_movies AS (
    SELECT
        t.title,
        t.production_year,
        a.name AS actor_name,
        r.role AS role_description
    FROM
        top_actors ta
    JOIN
        cast_info c ON ta.person_id = c.person_id
    JOIN
        title t ON c.movie_id = t.id
    JOIN
        role_type r ON c.role_id = r.id
    JOIN
        aka_name a ON a.person_id = c.person_id
)
SELECT
    actor_name,
    COUNT(*) AS movies_count,
    STRING_AGG(title || ' (' || production_year || ')', ', ') AS movie_list
FROM
    actor_movies
GROUP BY
    actor_name
ORDER BY
    movies_count DESC;
