WITH movie_actors AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        r.role AS actor_role,
        t.production_year
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        title t ON ci.movie_id = t.id
    JOIN
        role_type r ON ci.role_id = r.id
),
movie_keywords AS (
    SELECT
        t.title AS movie_title,
        array_agg(k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        title t ON mk.movie_id = t.id
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.title
),
complete_info AS (
    SELECT
        ma.actor_name,
        ma.movie_title,
        ma.actor_role,
        ma.production_year,
        COALESCE(mk.keywords, '{}') AS keywords
    FROM
        movie_actors ma
    LEFT JOIN
        movie_keywords mk ON ma.movie_title = mk.movie_title
)
SELECT
    actor_name,
    movie_title,
    actor_role,
    production_year,
    keywords
FROM
    complete_info
WHERE
    actor_name ILIKE '%Smith%'
ORDER BY
    production_year DESC, actor_name;
