WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
DirectorMovies AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS directors
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title m ON ci.movie_id = m.id
    WHERE 
        ci.role_id IN (SELECT id FROM role_type WHERE role = 'director')
    GROUP BY 
        m.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    dm.directors,
    CASE 
        WHEN rm.actor_count > 10 THEN 'Large Cast'
        WHEN rm.actor_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    RankedMovies rm
LEFT JOIN 
    DirectorMovies dm ON rm.movie_id = dm.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC
LIMIT 10;
