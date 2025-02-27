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
PopularMovies AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        RankedMovies m
    JOIN
        cast_info ci ON m.movie_id = ci.movie_id
    GROUP BY
        m.movie_id
    HAVING
        COUNT(DISTINCT ci.person_id) > 5
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
MovieDetails AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        mp.cast_count,
        mk.keywords
    FROM
        PopularMovies mp
    JOIN
        RankedMovies m ON mp.movie_id = m.movie_id
    LEFT JOIN
        MovieKeywords mk ON m.movie_id = mk.movie_id
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.keywords,
    COALESCE((
        SELECT
            STRING_AGG(c.name, ', ')
        FROM
            complete_cast cc
        JOIN
            aka_name c ON cc.subject_id = c.person_id
        WHERE
            cc.movie_id = md.movie_id
    ), 'No Cast') AS cast_names
FROM
    MovieDetails md
ORDER BY
    md.production_year DESC, md.cast_count DESC;
