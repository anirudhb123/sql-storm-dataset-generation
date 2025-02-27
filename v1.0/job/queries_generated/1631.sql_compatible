
WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
actor_movies AS (
    SELECT
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY
        c.person_id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    a.person_id AS actor_id,
    a.name,
    am.movie_count,
    r.title,
    r.production_year,
    mk.keywords
FROM
    aka_name a
LEFT JOIN
    actor_movies am ON a.person_id = am.person_id
LEFT JOIN
    ranked_titles r ON am.movie_count = 1 AND r.rn = 1
LEFT JOIN
    movie_keywords mk ON r.title_id = mk.movie_id
WHERE
    a.name LIKE '%Smith%'
ORDER BY
    a.name, r.production_year DESC
LIMIT 50;
