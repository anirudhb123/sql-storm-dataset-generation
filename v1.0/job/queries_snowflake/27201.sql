
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
),
TopRatedMovies AS (
    SELECT
        DISTINCT movie_id, movie_title, production_year, movie_keyword
    FROM
        RankedMovies
    WHERE
        rank <= 5
),
MovieDetails AS (
    SELECT
        t.movie_id,
        t.movie_title,
        t.production_year,
        COUNT(c.id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS full_cast_names
    FROM
        TopRatedMovies t
    LEFT JOIN
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        t.movie_id, t.movie_title, t.production_year
),
FinalOutput AS (
    SELECT
        md.movie_title,
        md.production_year,
        md.total_cast,
        md.full_cast_names,
        CASE 
            WHEN md.production_year > 2015 THEN 'Recent'
            ELSE 'Older'
        END AS movie_age_category
    FROM
        MovieDetails md
)
SELECT
    movie_title,
    production_year,
    total_cast,
    full_cast_names,
    movie_age_category
FROM
    FinalOutput
ORDER BY
    production_year DESC, total_cast DESC;
