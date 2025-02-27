WITH RecursiveMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        mt.id AS movie_id,
        COALESCE(ka.name, 'Unknown') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ca.nr_order) AS actor_order
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ca ON mt.id = ca.movie_id
    LEFT JOIN 
        aka_name ka ON ca.person_id = ka.person_id
    WHERE 
        mt.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        actor_name,
        COUNT(movie_id) AS movie_count
    FROM 
        RecursiveMovies
    GROUP BY 
        actor_name
),
PopularActors AS (
    SELECT 
        actor_name
    FROM 
        ActorMovieCounts
    WHERE 
        movie_count > (SELECT AVG(movie_count) FROM ActorMovieCounts)
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_name,
    CASE 
        WHEN pa.actor_name IS NOT NULL THEN 'Popular Actor'
        ELSE 'Regular Actor'
    END AS actor_status
FROM 
    RecursiveMovies rm
LEFT JOIN 
    PopularActors pa ON rm.actor_name = pa.actor_name
WHERE 
    rm.actor_order <= 3
ORDER BY 
    rm.production_year DESC, 
    rm.title;
