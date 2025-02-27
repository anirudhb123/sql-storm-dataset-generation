WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        0 AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = (SELECT MAX(production_year) FROM aka_title)

    UNION ALL

    SELECT 
        m.id,
        m.title,
        mh.level + 1 AS level,
        mh.movie_id
    FROM 
        movie_link ml 
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        title m ON ml.movie_id = m.id
)
SELECT 
    n.name AS person_name,
    a.title AS movie_title,
    ranked_roles.role_name,
    COUNT(DISTINCT cc.id) AS movies_count,
    AVG(mi.info) AS avg_movie_info
FROM 
    aka_name n
JOIN 
    cast_info ci ON n.person_id = ci.person_id
JOIN 
    title a ON ci.movie_id = a.id
LEFT JOIN 
    person_info pi ON n.person_id = pi.person_id 
LEFT JOIN 
    movie_info mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
JOIN 
    (SELECT 
         ci.role_id,
         rt.role AS role_name,
         RANK() OVER (PARTITION BY ci.person_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
     FROM 
         cast_info ci
     JOIN 
         role_type rt ON ci.role_id = rt.id
     GROUP BY 
         ci.role_id, rt.role
    ) ranked_roles ON ci.role_id = ranked_roles.role_id
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN 
    movie_hierarchy mh ON a.id = mh.movie_id
WHERE 
    a.production_year > 2000 AND 
    (mc.note IS NULL OR mc.note NOT LIKE '%canceled%') 
GROUP BY 
    n.name, a.title, ranked_roles.role_name
HAVING 
    COUNT(DISTINCT cc.id) > 5 
ORDER BY 
    avg_movie_info DESC, movies_count DESC;
