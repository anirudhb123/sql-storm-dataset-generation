WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC) AS rank
    FROM
        aka_title ak
    JOIN
        title m ON ak.movie_id = m.id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        cast_info c ON c.movie_id = m.id
    GROUP BY
        m.id,
        m.title,
        m.production_year
),
SelectedMovies AS (
    SELECT
        *
    FROM
        RankedMovies
    WHERE
        rank <= 10
)
SELECT
    sm.movie_id,
    sm.movie_title,
    sm.production_year,
    sm.aka_names,
    sm.keywords,
    sm.cast_count,
    COALESCE(mi.info, 'No info available') AS movie_info
FROM
    SelectedMovies sm
LEFT JOIN
    movie_info mi ON sm.movie_id = mi.movie_id
ORDER BY
    sm.production_year DESC;
