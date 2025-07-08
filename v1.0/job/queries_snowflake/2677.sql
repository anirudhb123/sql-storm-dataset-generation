
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS ranking
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.ranking <= 10
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(kc.keyword_total, 0) AS keyword_total,
    CASE 
        WHEN tm.actor_count > 5 THEN 'High Actor Count'
        WHEN tm.actor_count BETWEEN 3 AND 5 THEN 'Moderate Actor Count'
        ELSE 'Low Actor Count'
    END AS actor_category
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordCount kc ON kc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1) 
GROUP BY 
    tm.title, 
    tm.production_year, 
    tm.actor_count
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
