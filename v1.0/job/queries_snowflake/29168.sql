
WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
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
    COUNT(DISTINCT rm.actor_name) AS actor_count,
    LISTAGG(DISTINCT rm.actor_name, ', ') WITHIN GROUP (ORDER BY rm.actor_name) AS actors_list
FROM 
    RankedMovies rm
GROUP BY 
    rm.movie_title, rm.production_year
HAVING 
    COUNT(DISTINCT rm.actor_name) > 3
ORDER BY 
    rm.production_year DESC, actor_count DESC;
