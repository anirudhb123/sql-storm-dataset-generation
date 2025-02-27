WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    GROUP BY
        a.id
),
TopMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 5
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
MovieDetails AS (
    SELECT
        tm.title,
        tm.production_year,
        tm.cast_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM
        TopMovies tm
    LEFT JOIN MovieKeywords mk ON tm.cast_count = (SELECT MAX(cast_count) FROM TopMovies)
),
FinalOutput AS (
    SELECT
        md.title,
        md.production_year,
        md.cast_count,
        md.keywords,
        CASE
            WHEN md.cast_count IS NULL THEN 'Unknown'
            WHEN md.cast_count > 10 THEN 'Popular'
            ELSE 'Niche'
        END AS popularity_status
    FROM
        MovieDetails md
)
SELECT
    fo.title,
    fo.production_year,
    fo.cast_count,
    fo.keywords,
    fo.popularity_status
FROM
    FinalOutput fo
WHERE
    fo.production_year > 2000
    AND (fo.cast_count IS NOT NULL OR fo.keywords != 'No keywords')
ORDER BY
    fo.production_year DESC, fo.cast_count DESC;