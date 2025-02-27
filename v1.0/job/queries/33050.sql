
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    ka.name AS actor_name,
    a.title AS movie_title,
    ka.id AS actor_id,
    COUNT(DISTINCT cc.movie_id) AS total_movies,
    SUM(CASE WHEN cc.status_id IS NULL THEN 1 ELSE 0 END) AS total_undisclosed_casts,
    ROW_NUMBER() OVER (PARTITION BY ka.id ORDER BY COUNT(DISTINCT cc.movie_id) DESC) AS rank_movies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS associated_keywords,
    MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') THEN mi.info END) AS box_office_info
FROM 
    aka_name ka
JOIN 
    cast_info ci ON ka.person_id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_title a ON cc.movie_id = a.id
LEFT JOIN 
    movie_keyword mk ON a.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON a.id = mi.movie_id
WHERE 
    ka.name IS NOT NULL 
    AND a.production_year IS NOT NULL
GROUP BY 
    ka.id, a.title
HAVING 
    COUNT(DISTINCT cc.movie_id) > 5
ORDER BY 
    total_movies DESC, 
    actor_name;
