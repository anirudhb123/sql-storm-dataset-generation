WITH movie_actors AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.nr_order,
        p.info AS actor_info
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN
        person_info p ON a.person_id = p.person_id
    WHERE
        a.name IS NOT NULL
),
keyword_movies AS (
    SELECT
        t.title AS movie_title,
        k.keyword AS movie_keyword
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
),
actor_keywords AS (
    SELECT
        ma.actor_name,
        km.movie_keyword
    FROM
        movie_actors ma
    JOIN
        keyword_movies km ON ma.movie_title = km.movie_title
)
SELECT
    ak.actor_name,
    COUNT(DISTINCT ak.movie_keyword) AS total_keywords,
    STRING_AGG(DISTINCT ak.movie_keyword, ', ') AS keywords
FROM
    actor_keywords ak
GROUP BY
    ak.actor_name
ORDER BY
    total_keywords DESC
LIMIT 10;

