
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(c.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_count,
    COALESCE(rm.actors, 'No actors listed') AS actors,
    (SELECT COUNT(*) FROM title t WHERE t.production_year = rm.production_year AND t.kind_id = 1) AS total_movies_year,
    CASE 
        WHEN rm.actor_count = 0 THEN 'No actors'
        WHEN rm.actor_count > (SELECT AVG(actor_count) FROM RankedMovies) THEN 'Above average'
        ELSE 'Below average'
    END AS actor_count_status
FROM 
    RankedMovies rm
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
