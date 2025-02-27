WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 5 -- Limit recursion to 5 levels deep
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COALESCE(mh.level, 0) AS hierarchy_level,
    a.info AS actor_info,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(p.year) AS average_production_year
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    (SELECT 
         movie_id, 
         AVG(production_year) AS year 
     FROM 
         aka_title 
     GROUP BY 
         movie_id) p ON at.id = p.movie_id
LEFT JOIN 
    person_info a ON ak.person_id = a.person_id AND a.info_type_id = (SELECT id FROM info_type WHERE info = 'Bio')
WHERE 
    ak.name IS NOT NULL 
    AND (mh.level IS NOT NULL OR at.production_year > 2000)
GROUP BY 
    ak.name, at.title, mh.level, a.info
ORDER BY 
    keyword_count DESC, actor_name;
