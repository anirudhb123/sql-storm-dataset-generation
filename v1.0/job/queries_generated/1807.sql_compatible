
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL AND a.production_year IS NOT NULL
),
ActorsWithRoles AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        rt.role, 
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ARRAY_AGG(DISTINCT awr.actor_name) AS actors,
    COUNT(DISTINCT awr.actor_name) AS total_actors,
    CASE 
        WHEN COUNT(DISTINCT awr.actor_name) > 5 THEN 'Ensemble Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsWithRoles awr ON rm.movie_id = awr.movie_id
WHERE 
    rm.year_rank <= 10 
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
HAVING 
    COUNT(DISTINCT awr.actor_name) IS NOT NULL AND rm.production_year IS NOT NULL
ORDER BY 
    rm.production_year DESC, total_actors DESC;
