WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM aka_title a
    JOIN cast_info c ON a.id = c.movie_id
    WHERE a.production_year IS NOT NULL
    GROUP BY a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT title, production_year, actor_count
    FROM RankedMovies
    WHERE rank <= 5
),
CompanyCounts AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM complete_cast m
    JOIN movie_companies mc ON m.movie_id = mc.movie_id
    GROUP BY m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    COALESCE(cc.company_count, 0) AS company_count
FROM TopMovies tm
LEFT JOIN CompanyCounts cc ON tm.title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
ORDER BY tm.production_year DESC, tm.actor_count DESC;
