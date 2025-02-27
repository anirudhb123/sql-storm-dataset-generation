
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year, mt.id) AS rn
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
Actors AS (
    SELECT 
        c.person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.person_id, ak.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 3
),
MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.movie_title,
        COALESCE(SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_roles,
        COALESCE(STRING_AGG(ak.actor_name, ', '), 'No Cast') AS cast_names
    FROM 
        RankedMovies mt
    LEFT JOIN 
        cast_info c ON mt.movie_id = c.movie_id
    LEFT JOIN 
        Actors ak ON c.person_id = ak.person_id
    GROUP BY 
        mt.movie_id, mt.movie_title
)
SELECT 
    md.movie_title,
    RankedMovies.production_year,
    md.total_roles,
    md.cast_names
FROM 
    MovieDetails md
JOIN 
    RankedMovies ON md.movie_id = RankedMovies.movie_id
WHERE 
    md.total_roles > 0
ORDER BY 
    RankedMovies.production_year DESC, md.movie_title
LIMIT 10;
