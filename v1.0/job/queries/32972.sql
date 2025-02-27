
WITH RECURSIVE movie_hierarchy AS (
    
    SELECT 
        ml.movie_id AS base_movie,
        ml.linked_movie_id,
        1 AS level
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel') 

    UNION ALL

    SELECT 
        mh.base_movie,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
),

movie_keywords AS (
    
    SELECT 
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

movies_with_cast AS (
    
    SELECT 
        m.id AS movie_id,
        m.title,
        ak.name AS actor_name,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY ci.nr_order) AS role_order
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
)

SELECT 
    a.title AS movie_title,
    mh.linked_movie_id AS sequel_movie_id,
    COALESCE(mk.keywords, ARRAY[]::TEXT[]) AS keywords,
    STRING_AGG(DISTINCT CONCAT(a.actor_name, ' as ', a.role), ', ') AS cast_info,
    COUNT(DISTINCT a.actor_name) AS total_actors,
    MAX(a.role_order) AS max_role_order
FROM 
    movies_with_cast a
LEFT JOIN 
    movie_hierarchy mh ON a.movie_id = mh.base_movie
LEFT JOIN 
    movie_keywords mk ON a.movie_id = mk.movie_id
WHERE 
    a.movie_id IN (SELECT DISTINCT movie_id FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Genre') AND info LIKE '%Action%')
    AND mh.linked_movie_id IS NOT NULL
GROUP BY 
    a.title, mh.linked_movie_id, mk.keywords
ORDER BY 
    a.title, total_actors DESC;
