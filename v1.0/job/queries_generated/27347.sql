WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        aka_title AS t
    JOIN
        movie_companies AS mc ON t.movie_id = mc.movie_id
    JOIN
        company_name AS cn ON mc.company_id = cn.id
    JOIN
        company_type AS ct ON mc.company_type_id = ct.id
    JOIN
        cast_info AS ci ON t.movie_id = ci.movie_id
    LEFT JOIN
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN
        movie_keyword AS mk ON t.movie_id = mk.movie_id
    LEFT JOIN
        keyword AS kw ON mk.keyword_id = kw.id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY
        t.id, t.title, t.production_year, ct.kind
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        company_type,
        cast_count,
        aka_names,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY company_type ORDER BY cast_count DESC) AS rank
    FROM
        RankedMovies
)
SELECT
    movie_id,
    title,
    production_year,
    company_type,
    cast_count,
    aka_names,
    keywords
FROM
    TopMovies
WHERE
    rank <= 5
ORDER BY
    company_type, cast_count DESC;
