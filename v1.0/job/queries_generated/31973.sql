WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    mh.level,
    m.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) AS cast_count,
    AVG(COALESCE(pi.info_type_id, 0)) AS avg_info_type
FROM 
    MovieHierarchy mh
JOIN 
    aka_title m ON mh.movie_id = m.id
JOIN 
    cast_info ci ON ci.movie_id = m.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
GROUP BY 
    a.name, m.title, mh.level, m.production_year
HAVING 
    COUNT(DISTINCT mk.keyword) > 5
ORDER BY 
    mh.level DESC, m.production_year DESC, keyword_count DESC;
