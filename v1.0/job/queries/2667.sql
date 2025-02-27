WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_cast_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MoviesWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mc.actor_name,
        mc.role_name,
        mc.total_cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCast mc ON rm.movie_id = mc.movie_id
)
SELECT 
    mwa.movie_id,
    mwa.title,
    mwa.production_year,
    STRING_AGG(mwa.actor_name, ', ') AS actor_names,
    COUNT(DISTINCT mwa.actor_name) AS unique_actors,
    (CASE 
        WHEN COUNT(DISTINCT mwa.actor_name) > 5 THEN 'Ensemble Cast'
        WHEN COUNT(DISTINCT mwa.actor_name) BETWEEN 3 AND 5 THEN 'Moderate Cast'
        ELSE 'Minimal Cast'
    END) AS cast_size_category
FROM 
    MoviesWithActors mwa
GROUP BY 
    mwa.movie_id, mwa.title, mwa.production_year
HAVING 
    SUM(CASE WHEN mwa.role_name IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    mwa.production_year DESC, 
    unique_actors DESC;
