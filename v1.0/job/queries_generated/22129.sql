WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank_by_title
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorsWithRoles AS (
    SELECT 
        ak.person_id,
        ak.name,
        ci.movie_id,
        ci.role_id,
        r.role AS role_name,
        COUNT(*) OVER (PARTITION BY ak.person_id) AS total_roles
    FROM 
        aka_name AS ak
    JOIN 
        cast_info AS ci ON ak.person_id = ci.person_id
    JOIN 
        role_type AS r ON ci.role_id = r.id
    WHERE 
        ak.name IS NOT NULL
),
MoviesWithRoles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ARRAY_AGG(DISTINCT ar.role_name) AS roles,
        COUNT(DISTINCT ar.person_id) AS actor_count
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        ActorsWithRoles AS ar ON rm.movie_id = ar.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
FilteredMovies AS (
    SELECT 
        *,
        CASE 
            WHEN actor_count > 5 THEN 'Large Cast' 
            WHEN actor_count BETWEEN 3 AND 5 THEN 'Medium Cast' 
            ELSE 'Small Cast' 
        END AS cast_size
    FROM 
        MoviesWithRoles
),
FinalResult AS (
    SELECT 
        fm.title,
        fm.production_year,
        fm.cast_size,
        COALESCE(array_to_string(fm.roles, ', '), 'No Roles') AS roles,
        CASE 
            WHEN fm.production_year >= 2000 THEN 'Modern Era' 
            ELSE 'Classic Era' 
        END AS era
    FROM 
        FilteredMovies AS fm
    WHERE 
        EXISTS (
            SELECT 1
            FROM movie_info AS mi
            WHERE mi.movie_id = fm.movie_id 
              AND mi.info LIKE '%Award%'
        )
)
SELECT 
    fr.title,
    fr.production_year,
    fr.cast_size,
    fr.roles,
    fr.era
FROM 
    FinalResult AS fr
ORDER BY 
    fr.production_year DESC, fr.title;
