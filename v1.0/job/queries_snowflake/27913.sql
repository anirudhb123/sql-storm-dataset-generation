
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        movie_title,
        production_year
    FROM
        RankedMovies
    WHERE
        rank <= 10
),
MovieDetails AS (
    SELECT
        t.movie_id,
        ARRAY_AGG(DISTINCT c.person_id) AS cast_ids,
        ARRAY_AGG(DISTINCT c.role_id) AS role_ids,
        ARRAY_AGG(DISTINCT c.nr_order) AS order_of_appearance
    FROM
        complete_cast t
    JOIN
        cast_info c ON t.movie_id = c.movie_id
    GROUP BY
        t.movie_id
)
SELECT
    m.movie_id,
    m.movie_title,
    m.production_year,
    COALESCE(md.cast_ids, ARRAY_CONSTRUCT()) AS cast_ids,
    COALESCE(md.role_ids, ARRAY_CONSTRUCT()) AS role_ids,
    COALESCE(md.order_of_appearance, ARRAY_CONSTRUCT()) AS order_of_appearance
FROM
    TopMovies m
LEFT JOIN
    MovieDetails md ON m.movie_id = md.movie_id
ORDER BY
    m.production_year, m.movie_title;
