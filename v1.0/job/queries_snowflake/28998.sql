
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),

PopularActors AS (
    SELECT
        ca.movie_id,
        a.name AS actor_name,
        COUNT(ca.person_id) AS appearances
    FROM
        cast_info ca
    JOIN
        aka_name a ON ca.person_id = a.person_id
    GROUP BY
        ca.movie_id, a.name
    HAVING
        COUNT(ca.person_id) > 2
),

MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords_list
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),

FinalBenchmark AS (
    SELECT
        r.movie_id,
        r.movie_title,
        r.production_year,
        a.actor_name,
        k.keywords_list,
        r.year_rank
    FROM
        RankedMovies r
    LEFT JOIN
        PopularActors a ON r.movie_id = a.movie_id
    LEFT JOIN
        MovieKeywords k ON r.movie_id = k.movie_id
)

SELECT
    fb.movie_id,
    fb.movie_title,
    fb.production_year,
    fb.actor_name,
    fb.keywords_list,
    fb.year_rank
FROM
    FinalBenchmark fb
WHERE
    fb.year_rank <= 5
ORDER BY
    fb.production_year DESC, fb.movie_title;
