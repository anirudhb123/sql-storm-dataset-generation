
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        n.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        name n ON an.person_id = n.imdb_id
    JOIN 
        aka_title at ON t.id = at.movie_id
)

SELECT 
    rm.movie_title,
    LISTAGG(rm.actor_name, ', ' ) WITHIN GROUP (ORDER BY rm.actor_rank) AS cast_list
FROM 
    RankedMovies rm
GROUP BY 
    rm.movie_title
HAVING 
    COUNT(rm.actor_name) > 5
ORDER BY 
    COUNT(rm.actor_name) DESC;
