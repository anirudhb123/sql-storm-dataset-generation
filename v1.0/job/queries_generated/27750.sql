WITH movie_data AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ARRAY_AGG(DISTINCT co.name) AS company_names
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name co ON mc.company_id = co.id
    WHERE
        m.production_year >= 2000
    GROUP BY
        m.id, m.title, m.production_year
),
ranked_movies AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        movie_keyword,
        cast_names,
        company_names,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title) AS rank
    FROM
        movie_data
)
SELECT
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.movie_keyword,
    rm.cast_names,
    rm.company_names
FROM
    ranked_movies rm
WHERE
    rm.rank <= 5
ORDER BY
    rm.production_year ASC, rm.movie_title ASC;
