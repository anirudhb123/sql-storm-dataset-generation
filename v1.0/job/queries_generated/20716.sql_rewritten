WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ca.movie_id,
        ka.name AS actor_name,
        COALESCE(rt.role, 'Unknown Role') AS role,
        COUNT(*) AS total_roles
    FROM 
        cast_info ca
    JOIN 
        aka_name ka ON ca.person_id = ka.person_id
    LEFT JOIN 
        role_type rt ON ca.role_id = rt.id
    GROUP BY 
        ca.movie_id, ka.name, rt.role
),
MoviesWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_name,
        ar.role,
        ar.total_roles
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        mwa.title,
        mwa.production_year,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        COUNT(DISTINCT mwa.actor_name) AS actor_count
    FROM 
        MoviesWithActors mwa
    LEFT JOIN 
        KeywordCount kc ON mwa.movie_id = kc.movie_id
    WHERE 
        mwa.production_year > 2000
    GROUP BY 
        mwa.title, mwa.production_year, kc.keyword_count
    HAVING 
        COUNT(DISTINCT mwa.actor_name) > 1
)
SELECT 
    f.title,
    f.production_year,
    f.keyword_count,
    f.actor_count,
    CASE 
        WHEN f.actor_count > 5 THEN 'Ensemble Cast'
        WHEN f.actor_count BETWEEN 3 AND 5 THEN 'Supporting Cast'
        ELSE 'Solo Performance' 
    END AS cast_type
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC,
    f.keyword_count DESC,
    f.title;