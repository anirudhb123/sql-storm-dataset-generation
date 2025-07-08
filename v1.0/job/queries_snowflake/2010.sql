WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    (SELECT AVG(actor_count) FROM RankedMovies) AS avg_actor_count,
    CASE 
        WHEN rm.actor_count > (SELECT AVG(actor_count) FROM RankedMovies) THEN 'Above Average'
        WHEN rm.actor_count < (SELECT AVG(actor_count) FROM RankedMovies) THEN 'Below Average'
        ELSE 'Average'
    END AS performance_category
FROM 
    RankedMovies rm
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;