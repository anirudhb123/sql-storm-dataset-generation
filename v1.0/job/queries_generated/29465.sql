WITH RankedActors AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        COUNT(ci.movie_id) AS role_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name, ak.person_id
),
PopularMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(ci.person_id) AS total_cast
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.title, mt.production_year
    ORDER BY 
        total_cast DESC
    LIMIT 10
),
ActorMovieRoles AS (
    SELECT 
        ra.actor_name,
        pm.movie_title,
        pm.production_year,
        ra.role_count
    FROM 
        RankedActors ra
    JOIN 
        cast_info ci ON ra.person_id = ci.person_id
    JOIN 
        aka_title pm ON ci.movie_id = pm.id
    WHERE 
        ci.nr_order < 5  -- limit to the first 4 roles
)
SELECT 
    amr.actor_name,
    amr.movie_title,
    amr.production_year,
    amr.role_count,
    string_agg(DISTINCT ci.note, ', ') AS role_notes
FROM 
    ActorMovieRoles amr
JOIN 
    cast_info ci ON amr.person_id = ci.person_id
GROUP BY 
    amr.actor_name, amr.movie_title, amr.production_year, amr.role_count
ORDER BY 
    amr.role_count DESC;
