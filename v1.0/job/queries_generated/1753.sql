WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count
    FROM
        RankedMovies
    WHERE
        rank <= 5
),
MovieDetails AS (
    SELECT
        tm.title AS movie_title,
        tm.production_year,
        ak.name AS actor_name,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM
        TopMovies tm
    JOIN
        cast_info ci ON tm.movie_id = ci.movie_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        tm.movie_id, tm.title, tm.production_year, ak.name
)
SELECT
    movie_title,
    production_year,
    actor_name,
    (CASE 
         WHEN cast_count IS NULL THEN 'No keywords'
         ELSE ARRAY_TO_STRING(keywords, ', ')
     END) AS keywords
FROM
    MovieDetails
ORDER BY
    production_year DESC, movie_title;
