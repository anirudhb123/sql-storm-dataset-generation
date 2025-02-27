WITH movie_actors AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT a.id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id
),
movies_with_keywords AS (
    SELECT
        m.id AS movie_id,
        m.title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id, m.title
),
top_movies AS (
    SELECT
        mwk.movie_id,
        mwk.title,
        mwk.keywords,
        ma.actor_count,
        ma.actors
    FROM
        movies_with_keywords mwk
    JOIN
        movie_actors ma ON mwk.movie_id = ma.movie_id
    WHERE
        mwk.keywords LIKE '%action%' 
    ORDER BY
        ma.actor_count DESC
    LIMIT 10
)
SELECT
    t.title,
    t.keywords,
    t.actor_count,
    t.actors
FROM
    top_movies t
JOIN
    title ti ON t.movie_id = ti.id
ORDER BY
    t.actor_count DESC;