WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year
    FROM
        RankedMovies
    WHERE
        rank <= 10
),
PopularActors AS (
    SELECT
        ak.person_id,
        ak.name,
        COUNT(ci.movie_id) AS movie_count
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY
        ak.person_id, ak.name
    HAVING
        COUNT(ci.movie_id) > 5
),
MovieDetails AS (
    SELECT
        tm.title,
        tm.production_year,
        pa.name AS actor_name,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        TopMovies tm
    LEFT JOIN
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN
        PopularActors pa ON ci.person_id = pa.person_id
    LEFT JOIN
        movie_keyword mk ON tm.movie_id = mk.movie_id
    GROUP BY
        tm.title, tm.production_year, pa.name
)
SELECT
    md.title,
    md.production_year,
    md.actor_name,
    COALESCE(md.keyword_count, 0) AS keyword_collected,
    CASE 
        WHEN md.keyword_count IS NULL THEN 'No Keywords'
        ELSE 'Has Keywords'
    END AS keyword_status
FROM
    MovieDetails md
WHERE
    md.production_year BETWEEN 2000 AND 2020
ORDER BY
    md.production_year DESC,
    md.keyword_collected DESC;
