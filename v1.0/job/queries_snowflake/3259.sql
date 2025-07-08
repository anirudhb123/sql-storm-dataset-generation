WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT cc.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info cc ON mt.id = cc.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
), ActorInfo AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.person_id, ak.name
), ActorRank AS (
    SELECT 
        ai.name,
        ai.movie_count,
        RANK() OVER (ORDER BY ai.movie_count DESC) AS actor_rank
    FROM 
        ActorInfo ai
)

SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    ar.name AS top_actor,
    ar.movie_count AS top_actor_movies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRank ar ON rm.actor_count = ar.actor_rank
WHERE 
    rm.actor_count > 5
    OR (rm.production_year BETWEEN 2000 AND 2020 AND rm.actor_count IS NULL)
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
