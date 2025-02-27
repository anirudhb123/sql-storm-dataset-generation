WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level,
        ARRAY[mt.title] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1,
        mh.path || at.title
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT ch.name) AS character_count,
    STRING_AGG(DISTINCT mh.title || ' (' || mh.production_year || ')', ', ') AS linked_movies,
    COUNT(DISTINCT k.keyword) FILTER(WHERE k.keyword IS NOT NULL) AS keyword_count,
    MAX(CASE WHEN mt.kind_id = 1 THEN 'Featured' ELSE 'Non-featured' END) AS movie_type,
    SUM(CASE WHEN mt.production_year < 2000 THEN 1 ELSE 0 END) AS pre_2000_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    char_name ch ON ci.person_role_id = ch.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy mh ON mt.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name NOT LIKE '%Unknown%'
    AND mt.production_year >= 1900
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mt.id) > 5
ORDER BY 
    actor_name COLLATE "C" ASC NULLS LAST;
