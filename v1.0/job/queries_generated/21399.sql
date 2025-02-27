WITH RankedMovies AS (
    SELECT
        t.*,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS movie_count
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
        AND t.title NOT LIKE '%unreleased%'
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
),
TopRankedMovies AS (
    SELECT
        rm.*,
        COALESCE(SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY rm.id), 0) AS cast_count,
        ARRAY_AGG(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL) AS keywords
    FROM
        RankedMovies rm
    LEFT JOIN
        cast_info c ON rm.id = c.movie_id
    LEFT JOIN
        movie_keyword mk ON rm.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        rm.year_rank <= 5
)
SELECT
    t.id AS movie_id,
    t.title,
    t.production_year,
    t.movie_count,
    t.cast_count,
    t.keywords
FROM
    TopRankedMovies t
WHERE
    (t.cast_count > 0 OR t.production_year IS NULL) AND
    (t.keywords IS NOT NULL OR t.title ILIKE '%epic%')
ORDER BY
    t.production_year DESC, t.title
LIMIT 10;
