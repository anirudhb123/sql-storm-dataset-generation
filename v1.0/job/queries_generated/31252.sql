WITH RECURSIVE Movie_Hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        Movie_Hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT cc.role_id) AS role_count,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    SUM(CASE WHEN ai.note IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mh.production_year DESC) AS movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info cc ON ak.person_id = cc.person_id
JOIN 
    aka_title at ON cc.movie_id = at.id
LEFT JOIN 
    movie_keyword k ON at.id = k.movie_id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
LEFT JOIN 
    movie_info_idx ai ON at.id = ai.movie_id AND ai.info_type_id IN (
        SELECT id FROM info_type WHERE info = 'box_office'
    )
JOIN 
    Movie_Hierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.id, ak.name, at.title, mh.production_year
HAVING 
    COUNT(DISTINCT cc.role_id) >= 3 
    AND SUM(CASE WHEN ai.note IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    movie_rank, ak.name;
