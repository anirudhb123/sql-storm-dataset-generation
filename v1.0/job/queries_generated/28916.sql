WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        aka_title ak
    JOIN
        title m ON m.id = ak.movie_id
    LEFT JOIN
        cast_info c ON c.movie_id = m.id
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN
        keyword kw ON kw.id = mk.keyword_id
    GROUP BY
        m.id
),
MovieHighlights AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aka_names,
        CASE 
            WHEN rm.production_year >= 2000 THEN 'Modern'
            ELSE 'Classic'
        END AS era
    FROM
        RankedMovies rm
)
SELECT
    mh.title,
    mh.production_year,
    mh.cast_count,
    mh.aka_names,
    mh.era
FROM
    MovieHighlights mh
WHERE
    mh.cast_count > 5
ORDER BY
    mh.production_year DESC, mh.cast_count DESC
LIMIT 10;
