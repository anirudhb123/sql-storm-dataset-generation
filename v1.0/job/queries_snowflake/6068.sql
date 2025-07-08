WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        aka_title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS actor_count,
        SUM(CASE WHEN role_type.role = 'Director' THEN 1 ELSE 0 END) AS director_count
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    LEFT JOIN 
        cast_info ON aka_title.movie_id = cast_info.movie_id
    LEFT JOIN 
        role_type ON cast_info.role_id = role_type.id
    WHERE 
        aka_title.production_year >= 2000
    GROUP BY 
        title.title, aka_title.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_count,
        rm.director_count,
        COALESCE(mi.info, 'No additional info') AS additional_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.production_year = mi.movie_id
)
SELECT 
    movie_title,
    production_year,
    actor_count,
    director_count,
    additional_info
FROM 
    MovieDetails
WHERE 
    actor_count > 5
ORDER BY 
    production_year DESC, actor_count DESC
LIMIT 100;
