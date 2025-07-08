
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') AS aka_names,
        LISTAGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY
        t.id, t.title, t.production_year
),
RankedByCast AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        RankedMovies
)

SELECT
    r.rank,
    r.title,
    r.production_year,
    r.cast_count,
    r.aka_names,
    r.keywords
FROM
    RankedByCast r
WHERE
    r.production_year BETWEEN 2000 AND 2023
ORDER BY
    r.rank
LIMIT 10;
