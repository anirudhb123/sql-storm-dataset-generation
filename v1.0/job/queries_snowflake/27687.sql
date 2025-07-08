
WITH movie_keywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),

movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ak.imdb_index AS actor_index,
        mk.keywords,
        c.kind AS company_type
    FROM
        title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN
        movie_keywords mk ON t.id = mk.movie_id
    WHERE
        (t.production_year >= 2000 AND t.production_year <= 2023)
        AND ak.name IS NOT NULL
),

ranked_movies AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_name,
        md.actor_index,
        md.keywords,
        md.company_type,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.title) AS year_rank
    FROM
        movie_details md
)

SELECT
    movie_id,
    title,
    production_year,
    actor_name,
    actor_index,
    keywords,
    company_type,
    year_rank
FROM
    ranked_movies
WHERE
    year_rank <= 5
ORDER BY
    production_year DESC, title;
