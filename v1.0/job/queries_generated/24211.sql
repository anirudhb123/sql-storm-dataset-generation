WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title ASC) AS rank,
        COUNT(*) OVER (PARTITION BY at.production_year) AS total_movies
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role,
        ci.nr_order AS role_order,
        CASE 
            WHEN ci.nr_order IS NULL THEN 'Unknown Order'
            WHEN ci.nr_order = 1 THEN 'Lead Actor'
            ELSE 'Supporting Actor'
        END AS role_type
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
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
        ar.role_order,
        ar.role_type,
        COUNT(ar.actor_name) OVER (PARTITION BY rm.movie_id) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    WHERE 
        rm.rank <= 3
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    COALESCE(fm.role_type, 'No Roles') AS role_type,
    fm.actor_count,
    CASE 
        WHEN fm.actor_count > 5 THEN 'A Star-studded Cast'
        WHEN fm.actor_count BETWEEN 2 AND 5 THEN 'A Solid Cast'
        ELSE 'Solo Show'
    END AS cast_description,
    STRING_AGG(DISTINCT fm.actor_name, ', ') AS actors_list
FROM 
    FilteredMovies fm
GROUP BY 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.role_type,
    fm.actor_count
HAVING 
    SUM(fm.actor_count) IS NOT NULL
ORDER BY 
    fm.production_year DESC, fm.title;
