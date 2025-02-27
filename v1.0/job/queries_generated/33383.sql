WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  
      
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        ak.title,
        ak.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c.role_id) AS total_roles,
    STRING_AGG(DISTINCT r.role, ', ') AS roles_played,
    AVG(PI / NULLIF(m.production_year, 0)) AS avg_role_year_ratio
FROM 
    cast_info c
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    title m ON mh.movie_id = m.id
WHERE 
    mh.production_year BETWEEN 2000 AND 2022
GROUP BY 
    ak.name, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT c.role_id) > 1
ORDER BY 
    avg_role_year_ratio DESC
LIMIT 10;
