WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(MAX(CASE WHEN ki.info_type_id = (SELECT id FROM info_type WHERE info = 'runtime' LIMIT 1) THEN mi.info END), 'N/A') AS runtime,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN movie_info_idx idx ON m.id = idx.movie_id
    WHERE m.production_year > 2000
    GROUP BY m.id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.runtime,
        rm.company_count,
        rm.keyword_count,
        RANK() OVER (ORDER BY rm.company_count DESC, rm.keyword_count DESC) AS movie_rank
    FROM RankedMovies rm
)
SELECT 
    tm.title,
    tm.production_year,
    tm.runtime,
    tm.company_count,
    tm.keyword_count
FROM TopMovies tm
WHERE tm.movie_rank <= 10
ORDER BY tm.movie_rank;
