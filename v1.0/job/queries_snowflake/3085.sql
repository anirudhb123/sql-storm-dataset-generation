
WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM
        aka_title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    GROUP BY
        m.id, m.title, m.production_year
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        mk.keywords
    FROM
        RankedMovies rm
    LEFT JOIN
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE
        rm.year_rank <= 5
        AND rm.production_year IS NOT NULL
)
SELECT
    tm.title,
    COALESCE(tm.keywords, 'No keywords') AS keywords,
    tm.cast_count
FROM
    TopMovies tm
WHERE
    tm.cast_count > (
        SELECT AVG(cast_count)
        FROM TopMovies
    )
ORDER BY
    tm.production_year DESC,
    tm.title;
