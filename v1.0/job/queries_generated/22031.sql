WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    ak.name,
    m.title,
    m.production_year,
    COUNT(DISTINCT c.id) AS cast_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY m.production_year DESC) AS row_num,
    COALESCE(c2.kind, 'Unknown Role') AS character_type
FROM 
    aka_name ak
LEFT JOIN 
    cast_info c ON ak.person_id = c.person_id
LEFT JOIN 
    movie_hierarchy m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    role_type c2 ON c.role_id = c2.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = 
    (SELECT id FROM info_type WHERE info = 'Synopsis' LIMIT 1)
WHERE 
    ak.name IS NOT NULL
    AND m.production_year >= 2000
    AND (c.nr_order IS NULL OR c.nr_order < 5)
GROUP BY 
    ak.name, m.title, m.production_year, character_type
HAVING 
    COUNT(DISTINCT c.id) > 0
ORDER BY 
    m.production_year DESC, ak.name;
