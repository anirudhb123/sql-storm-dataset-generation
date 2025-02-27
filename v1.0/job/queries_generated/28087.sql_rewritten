WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM
        aka_title a
    LEFT JOIN
        cast_info ci ON a.movie_id = ci.movie_id
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        a.id, a.title, a.production_year
),
HighCastMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aka_names
    FROM
        RankedMovies rm
    WHERE
        rm.cast_count >= 5  
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
MovieInfo AS (
    SELECT
        m.movie_id,
        STRING_AGG(mi.info, '; ') AS movie_info
    FROM
        movie_info m
    JOIN
        movie_info_idx mi ON m.id = mi.movie_id
    GROUP BY
        m.movie_id
)
SELECT
    hcm.movie_id,
    hcm.title,
    hcm.production_year,
    hcm.cast_count,
    hcm.aka_names,
    mk.keywords,
    mi.movie_info
FROM
    HighCastMovies hcm
LEFT JOIN
    MovieKeywords mk ON hcm.movie_id = mk.movie_id
LEFT JOIN
    MovieInfo mi ON hcm.movie_id = mi.movie_id
ORDER BY
    hcm.production_year DESC;