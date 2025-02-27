WITH movie_years AS (
    SELECT
        title AS movie_title,
        production_year,
        t.id AS title_id
    FROM
        title t
    WHERE
        production_year IS NOT NULL
),
actors_info AS (
    SELECT
        ak.name AS actor_name,
        p.gender,
        ci.movie_id,
        mv.movie_title
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    JOIN
        movie_years mv ON ci.movie_id = mv.title_id
    JOIN
        name p ON ak.person_id = p.imdb_id
    WHERE
        ak.name IS NOT NULL AND
        p.gender IS NOT NULL
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
),
detailed_info AS (
    SELECT
        ai.actor_name,
        ai.gender,
        mv.movie_title,
        mv.production_year,
        ARRAY_AGG(DISTINCT mk.keyword) AS keywords
    FROM
        actors_info ai
    JOIN
        movie_keywords mk ON ai.movie_id = mk.movie_id
    GROUP BY
        ai.actor_name, ai.gender, mv.movie_title, mv.production_year
)
SELECT
    di.actor_name,
    di.gender,
    di.movie_title,
    di.production_year,
    STRING_AGG(DISTINCT di.keywords::text, ', ') AS movie_keywords
FROM
    detailed_info di
WHERE
    di.production_year >= 2000
GROUP BY
    di.actor_name, di.gender, di.movie_title, di.production_year
ORDER BY
    di.production_year DESC, di.actor_name;
