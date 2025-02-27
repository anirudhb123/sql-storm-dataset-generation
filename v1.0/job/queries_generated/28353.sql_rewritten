WITH movie_actors AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.id) AS actor_appearance_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id, a.name
),

popular_movies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ca.actor_name) AS unique_actor_count
    FROM
        aka_title m
    JOIN
        movie_info mi ON m.id = mi.movie_id
    JOIN
        movie_actors ca ON m.id = ca.movie_id
    GROUP BY
        m.id, m.title, m.production_year
    HAVING
        COUNT(DISTINCT ca.actor_name) > 5 
),

movie_keywords AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
)

SELECT
    pm.movie_id,
    pm.title,
    pm.production_year,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    pm.unique_actor_count
FROM
    popular_movies pm
LEFT JOIN
    movie_keywords mk ON pm.movie_id = mk.movie_id
GROUP BY
    pm.movie_id, pm.title, pm.production_year, pm.unique_actor_count
ORDER BY
    pm.unique_actor_count DESC, pm.production_year DESC;