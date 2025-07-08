
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(c.movie_id) > 5
)
SELECT 
    rm.title,
    rm.production_year,
    ad.name AS actor_name,
    ad.movie_count,
    COALESCE(mi.info, 'No info available') AS movie_info,
    CASE 
        WHEN rm.actor_rank IS NULL THEN 'N/A'
        ELSE CAST(rm.actor_rank AS VARCHAR)
    END AS actor_rank
FROM 
    RankedMovies rm
JOIN 
    ActorDetails ad ON ad.movie_count = (SELECT MAX(movie_count) FROM ActorDetails)
LEFT JOIN 
    movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, 
    actor_rank;
