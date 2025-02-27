WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || at.title AS VARCHAR(255))
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5 -- limit levels for performance
)

SELECT 
    ch.name AS character_name,
    ak.name AS actor_name,
    m.title AS movie_title,
    COUNT(DISTINCT c.id) AS cast_count,
    ARRAY_AGG(DISTINCT ih.info) AS info,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY m.production_year DESC) AS recent_role
FROM 
    cast_info AS c
JOIN 
    aka_name AS ak ON c.person_id = ak.person_id
JOIN 
    title AS m ON c.movie_id = m.id
LEFT JOIN 
    char_name AS ch ON c.role_id = ch.id
LEFT JOIN 
    movie_info AS ih ON m.id = ih.movie_id
WHERE 
    m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Movie%')
    AND (ih.info IS NOT NULL OR h.info IS NULL) -- NULL logic
GROUP BY 
    character_name,
    actor_name,
    m.title
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    recent_role, 
    actor_name;

-- Performance benchmarking can focus on the execution time and resource usage of this query.
