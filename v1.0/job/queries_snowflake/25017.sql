
WITH RankedMovies AS (
    SELECT
        at.id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY
        at.id, at.title, at.production_year
),

PopularMovies AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        cast_count,
        aka_names,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        RankedMovies
    WHERE
        production_year >= 2000
)

SELECT
    pm.movie_id,
    pm.movie_title,
    pm.production_year,
    pm.cast_count,
    pm.aka_names,
    pm.keywords
FROM
    PopularMovies pm
WHERE
    pm.rank <= 10
ORDER BY
    pm.cast_count DESC, pm.movie_title ASC;
