
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023 

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        ak.title AS movie_title,
        ak.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 3 
)

SELECT 
    a.name AS actor_name,
    LISTAGG(DISTINCT mh.movie_title, ', ') WITHIN GROUP (ORDER BY mh.movie_title) AS movies,
    AVG(COALESCE(ci.nr_order, 0)) AS avg_order,
    COUNT(DISTINCT mi.id) AS movie_info_count
FROM 
    cast_info ci
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON mh.movie_id = ci.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, mh.movie_title, ci.nr_order
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1 
ORDER BY 
    avg_order DESC, 
    a.name ASC
LIMIT 10;
