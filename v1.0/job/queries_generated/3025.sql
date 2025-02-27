WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_actors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_name,
        ar.role,
        ar.total_actors
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    WHERE 
        rm.rn <= 5 AND 
        ar.role IS NOT NULL
)
SELECT 
    f.title,
    f.production_year,
    ARRAY_AGG(DISTINCT f.actor_name) AS actor_names,
    COUNT(DISTINCT f.actor_name) AS unique_actor_count,
    CASE 
        WHEN f.total_actors IS NOT NULL THEN f.total_actors
        ELSE 0
    END AS total_actors_in_movie
FROM 
    FilteredMovies f
GROUP BY 
    f.title, f.production_year
ORDER BY 
    f.production_year DESC, unique_actor_count DESC;
