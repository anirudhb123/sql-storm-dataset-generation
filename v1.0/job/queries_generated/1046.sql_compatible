
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
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    CASE 
        WHEN md.actor_count > 5 THEN 'Ensemble Cast'
        WHEN md.actor_count = 0 THEN 'Unknown'
        ELSE 'Standard Cast'
    END AS cast_type,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_info mi 
     WHERE 
        mi.movie_id = md.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
    ) AS genre_count
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2023 
    AND md.actor_count IS NOT NULL
ORDER BY 
    md.production_year DESC, md.actor_count DESC
LIMIT 50;
