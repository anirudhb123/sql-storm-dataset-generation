WITH MovieStatistics AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS production_companies_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    GROUP BY t.id
),
TopMovies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.cast_count,
        ms.production_companies_count,
        DENSE_RANK() OVER (ORDER BY ms.cast_count DESC) AS rank_by_cast
    FROM MovieStatistics ms
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.production_companies_count,
    COALESCE(NULLIF(tm.cast_count, 0), 1) AS adjusted_cast_count,
    CASE 
        WHEN tm.production_companies_count > 0 THEN 'Produced' 
        ELSE 'Independent' 
    END AS production_status,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = tm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline')) AS tagline_count
FROM TopMovies tm
WHERE tm.rank_by_cast <= 10
ORDER BY tm.cast_count DESC, tm.production_year DESC
LIMIT 5;
