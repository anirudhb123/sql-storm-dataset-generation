
WITH MovieDetails AS (
    SELECT
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        p.info AS person_info
    FROM
        aka_title a
    JOIN
        movie_keyword mk ON a.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON a.id = mc.movie_id
    JOIN
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        person_info p ON ci.person_id = p.person_id
    WHERE
        a.production_year BETWEEN 2000 AND 2023
        AND k.keyword ILIKE '%action%'
),

Summary AS (
    SELECT
        movie_id,
        movie_title,
        COUNT(movie_keyword) AS keyword_count,
        ARRAY_AGG(DISTINCT company_type) AS companies_involved,
        ARRAY_AGG(DISTINCT person_info) AS cast_info,
        MAX(production_year) AS production_year
    FROM
        MovieDetails
    GROUP BY
        movie_id, movie_title
    ORDER BY
        movie_title
)

SELECT
    movie_id,
    movie_title,
    keyword_count,
    companies_involved,
    cast_info
FROM
    Summary
WHERE
    keyword_count > 2
    AND movie_title LIKE 'A%'
ORDER BY
    production_year DESC;
