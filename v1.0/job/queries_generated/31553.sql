WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT cc.id) AS total_casts,
    AVG(mh.depth) AS avg_hierarchy_depth,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    (CASE WHEN MAX(ci.note) IS NULL THEN 'No notes' ELSE MAX(ci.note) END) AS last_role_note
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
LEFT JOIN 
    complete_cast cc ON at.id = cc.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND at.production_year >= 2000
GROUP BY 
    ak.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT cc.id) > 2 
    AND AVG(mh.depth) < 3
ORDER BY 
    total_casts DESC, avg_hierarchy_depth ASC;
