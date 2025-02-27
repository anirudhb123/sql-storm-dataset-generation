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
    
    UNION ALL
    
    SELECT 
        mv.linked_movie_id,
        m.title,
        m.production_year,
        h.level + 1
    FROM 
        movie_link mv
    JOIN 
        MovieHierarchy h ON mv.movie_id = h.movie_id
    JOIN 
        aka_title m ON mv.linked_movie_id = m.id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    COALESCE(GROUP_CONCAT(DISTINCT kw.keyword), 'No keywords') AS keywords,
    COUNT(DISTINCT c.role_id) AS roles_count,
    AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END) AS avg_info_length,
    mh.level AS movie_level
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title mt ON c.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id
JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND (mt.production_year >= 2000 OR mt.production_year IS NULL)
GROUP BY 
    ak.name, mt.title, mh.level
ORDER BY 
    mh.level DESC, roles_count DESC, avg_info_length DESC
LIMIT 50;
