WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS total_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_within_year
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'short'))
    GROUP BY
        t.id, t.title, t.production_year
),
MovieKeywordCounts AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        COALESCE(mkc.keyword_count, 0) AS keyword_count
    FROM
        RankedMovies rm
    LEFT JOIN
        MovieKeywordCounts mkc ON rm.movie_id = mkc.movie_id
    WHERE
        rm.rank_within_year <= 5
)
SELECT
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.keyword_count,
    CASE 
        WHEN tm.keyword_count > 5 THEN 'High'
        WHEN tm.keyword_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low' 
    END AS keyword_intensity,
    COALESCE(ci.note, 'No additional information') AS cast_note
FROM
    TopMovies tm
LEFT JOIN
    cast_info ci ON tm.movie_id = ci.movie_id
WHERE
    ci.note IS NULL OR ci.note LIKE '%lead%'
ORDER BY
    tm.production_year DESC, tm.total_cast DESC;
