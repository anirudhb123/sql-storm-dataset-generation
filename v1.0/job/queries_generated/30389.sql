WITH RECURSIVE movie_hierarchy AS (
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
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year >= 2000
)
SELECT 
    DISTINCT a.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mj.keyword_id) AS keyword_count,
    AVG(COALESCE(mi.info_type_id, 0)) AS average_info_type,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER(PARTITION BY at.title ORDER BY mh.level DESC) AS rank
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
LEFT JOIN 
    movie_keyword mj ON mh.movie_id = mj.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
JOIN 
    aka_title at ON mh.movie_id = at.id
LEFT JOIN 
    keyword k ON mj.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, at.title, mh.production_year
HAVING 
    COUNT(DISTINCT mj.keyword_id) > 0 
    AND AVG(COALESCE(mi.info_type_id, NULL)) IS NOT NULL
ORDER BY 
    mh.production_year DESC, keyword_count DESC, rank;
