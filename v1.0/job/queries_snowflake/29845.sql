
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        RankedMovies rm
    LEFT JOIN
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        rm.movie_id, rm.title, rm.production_year
),
MoviesWithGenres AS (
    SELECT
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        mwk.keywords,
        ARRAY_AGG(DISTINCT kt.kind) AS genres
    FROM
        MoviesWithKeywords mwk
    JOIN
        aka_title at ON mwk.movie_id = at.id
    JOIN
        kind_type kt ON at.kind_id = kt.id
    GROUP BY
        mwk.movie_id, mwk.title, mwk.production_year, mwk.keywords
)
SELECT
    mwg.movie_id,
    mwg.title,
    mwg.production_year,
    mwg.keywords,
    mwg.genres,
    CASE 
        WHEN mwg.production_year < 2000 THEN 'Classic'
        WHEN mwg.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    mwg.genres[ARRAY_SIZE(mwg.genres)] AS last_genre
FROM
    MoviesWithGenres mwg
ORDER BY
    mwg.production_year DESC, mwg.title;
