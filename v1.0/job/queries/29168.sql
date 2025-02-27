WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        row_number() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
)
SELECT 
    rm.movie_title,
    rm.production_year,
    COUNT(DISTINCT ak.name) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors_list
FROM 
    RankedMovies rm
JOIN 
    aka_name ak ON rm.actor_name = ak.name
GROUP BY 
    rm.movie_title, rm.production_year
HAVING 
    COUNT(DISTINCT ak.name) > 3
ORDER BY 
    rm.production_year DESC, actor_count DESC;