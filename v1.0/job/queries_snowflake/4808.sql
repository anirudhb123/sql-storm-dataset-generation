WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieActors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.id) AS role_count,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY COUNT(DISTINCT c.id) DESC) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ma.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(ma.role_count, 0) AS role_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieActors ma ON rm.movie_id = ma.movie_id AND ma.actor_rank = 1
WHERE 
    rm.production_year IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    rm.movie_id;
