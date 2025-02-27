WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        production_year BETWEEN 2000 AND 2023
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.depth,
    COUNT(DISTINCT m.keyword) AS keyword_count,
    AVG(pi.info_length) AS average_info_length
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
) m ON at.id = m.movie_id
LEFT JOIN (
    SELECT 
        movie_id,
        AVG(LENGTH(info)) AS info_length
    FROM 
        movie_info
    GROUP BY 
        movie_id
) pi ON at.id = pi.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND at.production_year IS NOT NULL
    AND (ak.name ILIKE '%Smith%' OR ak.name ILIKE '%Jones%')
GROUP BY 
    ak.name, at.title, mh.depth
HAVING 
    AVG(pi.info_length) > 50 
ORDER BY 
    mh.depth ASC, keyword_count DESC;
