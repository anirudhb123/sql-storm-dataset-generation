WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM
        aka_title mt
    LEFT JOIN
        aka_name ak ON mt.id = ak.person_id
    LEFT JOIN
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON mt.id = mc.movie_id
    WHERE
        mt.production_year > 2000
    GROUP BY
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM
        RankedMovies
)
SELECT
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.aka_names,
    tm.keywords,
    tm.cast_count,
    tm.production_companies
FROM
    TopMovies tm
WHERE
    tm.rank <= 10
ORDER BY
    tm.cast_count DESC, tm.production_year DESC;
