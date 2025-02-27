WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id, 
        ci.movie_id, 
        1 AS depth
    FROM 
        cast_info ci
    WHERE 
        ci.role_id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ci.person_id, 
        ci.movie_id, 
        ah.depth + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE 
        ci.person_id <> ah.person_id
),
RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id
),
FilteredActors AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT ah.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        ActorHierarchy ah ON ak.person_id = ah.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ah.movie_id) > 2
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    fa.name AS popular_actor,
    fa.movie_count
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredActors fa ON rm.total_cast > 10
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;

