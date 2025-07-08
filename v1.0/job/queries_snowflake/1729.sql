WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(cc.id) AS cast_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.id) DESC) AS rank_by_year
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
ActorCounts AS (
    SELECT 
        na.name AS actor_name,
        COUNT(DISTINCT cc.movie_id) AS movie_count
    FROM 
        aka_name na
    JOIN 
        cast_info ci ON na.person_id = ci.person_id
    LEFT JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    GROUP BY 
        na.id, na.name
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    ac.actor_name,
    ac.movie_count,
    NULLIF(ac.movie_count, 0) AS adjusted_movie_count
FROM 
    RankedMovies rm
JOIN 
    ActorCounts ac ON rm.cast_count = ac.movie_count
WHERE 
    rm.rank_by_year <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC
LIMIT 20;
