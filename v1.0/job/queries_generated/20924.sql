WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
    
    UNION ALL
    
    SELECT 
        mt.id,
        CONCAT(parent.movie_title, ' -> ', mt.title) AS movie_title,
        mt.production_year,
        level + 1
    FROM 
        aka_title mt
    INNER JOIN movie_link ml ON ml.linked_movie_id = mt.id
    INNER JOIN MovieHierarchy parent ON ml.movie_id = parent.movie_id
),

ActorInfo AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT cc.movie_id) AS movie_count,
        STRING_AGG(DISTINCT ak.name ORDER BY ak.name) AS co_actors
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ci.person_id = ak.person_id
    LEFT JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) >= 3
),

MovieKeywords AS (
    SELECT 
        mt.title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.title
    HAVING 
        COUNT(mk.keyword_id) > 0
)

SELECT 
    mh.movie_title,
    mh.production_year,
    ai.name AS actor_name,
    ai.movie_count,
    ai.co_actors,
    mk.keyword_count
FROM 
    MovieHierarchy mh
JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
JOIN 
    aka_name ai ON ai.person_id = ci.person_id
JOIN 
    MovieKeywords mk ON mk.title = mh.movie_title
WHERE 
    mh.production_year < 2000 
    AND ai.name IS NOT NULL 
    AND mk.keyword_count > 1
ORDER BY 
    mh.production_year DESC, 
    ai.movie_count DESC, 
    mk.keyword_count DESC;
