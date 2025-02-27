WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
      
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        mh.movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.level AS movie_level,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    MAX(CASE WHEN ci.note IS NOT NULL THEN ci.note ELSE 'No Note' END) AS notes,
    COUNT(DISTINCT CASE WHEN mi.info IS NOT NULL THEN mi.info END) AS movie_info_count,
    RANK() OVER (PARTITION BY mh.parent_movie_id ORDER BY mh.production_year DESC) AS production_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
WHERE 
    mh.production_year >= 2000 
    AND (ci.person_role_id IS NOT NULL OR ci.role_id IS NOT NULL)
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, at.title, mh.level, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 3
ORDER BY 
    mh.production_year DESC, ak.name;
