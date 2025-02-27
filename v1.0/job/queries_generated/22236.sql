WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS movie_rank
    FROM aka_title mt
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorInfo AS (
    SELECT 
        akn.person_id,
        akn.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) as movie_count,
        STRING_AGG(DISTINCT mt.title, ', ') AS movies_involved
    FROM aka_name akn
    JOIN cast_info ci ON akn.person_id = ci.person_id
    JOIN RecursiveMovieCTE mt ON ci.movie_id = mt.movie_id
    GROUP BY akn.person_id, akn.name
),
RankedActors AS (
    SELECT 
        ai.actor_name,
        ai.movie_count,
        RANK() OVER (ORDER BY ai.movie_count DESC) AS actor_rank
    FROM ActorInfo ai
    WHERE ai.movie_count > 1
),
TheaterPerformance AS (
    SELECT 
        ra.actor_name,
        ra.movie_count,
        (SELECT AVG(ai.movie_count) FROM ActorInfo ai) AS average_movies_per_actor,
        CASE 
            WHEN ra.movie_count > (SELECT AVG(ai.movie_count) FROM ActorInfo ai) THEN 'Above Average'
            WHEN ra.movie_count = (SELECT AVG(ai.movie_count) FROM ActorInfo ai) THEN 'Average'
            ELSE 'Below Average'
        END AS performance_category
    FROM RankedActors ra
)
SELECT 
    tp.actor_name,
    tp.movie_count,
    tp.average_movies_per_actor,
    tp.performance_category,
    COALESCE(NULLIF(tp.performance_category, 'Average'), 'Not Categorized') AS categorized_performance
FROM TheaterPerformance tp
ORDER BY tp.movie_count DESC, tp.actor_name ASC
LIMIT 10;

-- Include a bizarre case to handle NULL logic comprehensively
SELECT
    DISTINCT v1.actor_name,
    v1.movie_count,
    CASE 
        WHEN v2.actor_name IS NULL AND v1.movie_count < 5 THEN 'Underachiever'
        WHEN v2.actor_name IS NOT NULL THEN 'Collaborative'
        ELSE 'Independent'
    END AS collaboration_status
FROM ActorInfo v1
LEFT JOIN ActorInfo v2 ON v1.person_id = v2.person_id
WHERE COALESCE(v1.movie_count, 0) BETWEEN 1 AND 10

UNION ALL

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    'Legacy' AS collaboration_status
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
WHERE ak.name ILIKE '%Smith%'
GROUP BY ak.name
ORDER BY 2 DESC;
