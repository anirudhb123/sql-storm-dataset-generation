WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ak.name) AS actor_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    STRING_AGG(DISTINCT rm.actor_name, ', ') AS actors,
    rm.cast_count
FROM 
    RankedMovies rm
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
HAVING 
    rm.cast_count > 5
ORDER BY 
    rm.production_year DESC, rm.title;
