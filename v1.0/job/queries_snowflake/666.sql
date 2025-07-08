WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
popular_movies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.cast_count,
        (SELECT AVG(r2.cast_count) 
         FROM ranked_movies r2 
         WHERE r2.production_year = r.production_year) AS avg_cast_count
    FROM 
        ranked_movies r
    WHERE 
        r.year_rank <= 5
)
SELECT 
    pm.title,
    pm.production_year,
    pm.cast_count,
    pm.avg_cast_count,
    CASE 
        WHEN pm.cast_count > pm.avg_cast_count THEN 'Above Average'
        WHEN pm.cast_count = pm.avg_cast_count THEN 'Average'
        ELSE 'Below Average'
    END AS cast_performance,
    ak.name AS actor_name
FROM 
    popular_movies pm
LEFT JOIN 
    cast_info ci ON pm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    ak.name IS NOT NULL
ORDER BY 
    pm.production_year DESC, 
    pm.cast_count DESC;
