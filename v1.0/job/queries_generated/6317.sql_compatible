
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
)
SELECT 
    rm.title,
    rm.production_year,
    STRING_AGG(rm.actor_name ORDER BY rm.actor_rank) AS actor_list
FROM 
    RankedMovies rm
GROUP BY 
    rm.title, rm.production_year
HAVING 
    COUNT(rm.actor_name) > 5
ORDER BY 
    rm.production_year DESC, rm.title ASC;
