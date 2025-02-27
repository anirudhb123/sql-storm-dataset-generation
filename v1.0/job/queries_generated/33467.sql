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
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c.id) AS total_roles,
    AVG(CASE 
            WHEN p.info IS NOT NULL THEN LENGTH(p.info) 
            ELSE 0 
        END) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY COUNT(DISTINCT c.id) DESC) AS role_rank,
    MAX(mh.depth) AS max_link_depth
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id 
LEFT JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id
GROUP BY 
    a.name, 
    t.title, 
    t.production_year
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    total_roles DESC,
    avg_info_length DESC
LIMIT 100;
