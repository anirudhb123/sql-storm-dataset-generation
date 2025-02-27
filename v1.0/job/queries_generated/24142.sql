WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL
        
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

, CleverActors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM movie_info mi
                    WHERE mi.movie_id = ci.movie_id
                      AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
                      AND mi.info IS NOT NULL
                ) THEN 1 
                ELSE 0 
            END) AS rated_movies_count
    FROM
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 10
)

SELECT 
    mh.title AS movie_title,
    mh.production_year,
    ca.actor_name,
    ca.movie_count,
    ca.rated_movies_count,
    CASE
        WHEN ca.rated_movies_count = 0 THEN 'No Ratings'
        WHEN ca.rated_movies_count < mh.level THEN 'Underachiever'
        ELSE 'Highly Rated Actor'
    END AS actor_performance
FROM 
    MovieHierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    CleverActors ca ON ca.actor_id = ci.person_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
    AND (mh.production_year IS NOT NULL OR mh.title IS NOT NULL)
ORDER BY 
    mh.production_year DESC, 
    ca.movie_count DESC, 
    actor_performance
LIMIT 50;

This SQL query utilizes several advanced concepts, including CTEs for recursive movie linking, complex aggregate calculations for actor movie participation, conditional logic for actor performance categorization based on their movies' ratings, and ordering results based on several criteria. The query filters out actors with fewer than ten movies and includes NULL logic to ensure robust handling of potential missing data.
