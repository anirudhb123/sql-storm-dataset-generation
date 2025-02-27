WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
RankedActors AS (
    SELECT 
        ak.name,
        amc.movie_count,
        RANK() OVER (ORDER BY amc.movie_count DESC) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        ActorMovieCounts amc ON ak.person_id = amc.person_id
),
MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        info.info AS movie_info
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info info ON mt.id = info.movie_id
)

SELECT 
    rh.movie_id,
    rh.title,
    rh.production_year,
    COALESCE(mi.movie_info, 'No additional info') AS movie_info,
    ra.name AS actor_name,
    ra.actor_rank
FROM 
    MovieHierarchy rh
LEFT JOIN 
    MovieInfo mi ON rh.movie_id = mi.movie_id
JOIN 
    cast_info ci ON rh.movie_id = ci.movie_id
JOIN 
    RankedActors ra ON ci.person_id = ra.person_id
WHERE 
    ra.actor_rank <= 10
ORDER BY 
    rh.production_year DESC, ra.actor_rank
LIMIT 50;

-- This query retrieves the top 10 actors with the most movie appearances since 2000, 
-- along with the movies they appeared in and any available movie info, 
-- displaying a hierarchy of linked movies as well. The result is
-- limited to the latest 50 movie entries while considering NULL values for missing info.
