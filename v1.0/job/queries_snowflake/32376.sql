
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year > 2000  

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.depth < 3  
)

SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    at.production_year AS year,
    COUNT(DISTINCT c.person_id) AS total_actors,
    LISTAGG(DISTINCT ak.keyword, ', ') WITHIN GROUP (ORDER BY ak.keyword) AS keywords,
    RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id AND c.movie_id = mh.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    aka_title at ON c.movie_id = at.id 
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword ak ON mk.keyword_id = ak.id
WHERE 
    a.name IS NOT NULL 
    AND at.kind_id IS NOT NULL
    AND ak.keyword IS NOT NULL
GROUP BY 
    a.name, at.title, at.production_year
ORDER BY 
    year DESC, total_actors DESC
LIMIT 10;
