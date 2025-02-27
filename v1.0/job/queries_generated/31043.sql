WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id, 
        mt.title, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    p.name AS actor_name,
    COUNT(DISTINCT ch.name) AS character_count,
    AVG(COALESCE(w.rank, 0)) AS average_rank,
    ARRAY_AGG(DISTINCT title.title) AS titles,
    SUM(CASE WHEN ct.kind = 'Lead' THEN 1 ELSE 0 END) AS lead_roles,
    SUM(CASE WHEN ct.kind IS NULL THEN 1 ELSE 0 END) AS unknown_roles
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
LEFT JOIN 
    char_name ch ON c.role_id = ch.id
JOIN 
    movie_hierarchy mh ON mh.movie_id = c.movie_id
LEFT JOIN 
    role_type rt ON c.person_role_id = rt.id
LEFT JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
LEFT JOIN (
    SELECT 
        movie_id, 
        DENSE_RANK() OVER (PARTITION BY movie_id ORDER BY COUNT(*) DESC) AS rank
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
) w ON mh.movie_id = w.movie_id
WHERE 
    mh.level <= 2
GROUP BY 
    p.name
HAVING 
    COUNT(DISTINCT ch.name) > 0
ORDER BY 
    average_rank DESC NULLS LAST
LIMIT 50;
