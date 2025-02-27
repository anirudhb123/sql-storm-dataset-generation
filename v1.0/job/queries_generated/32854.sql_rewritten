WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        h.level + 1
    FROM 
        movie_hierarchy h
    JOIN 
        movie_link ml ON h.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        h.level < 3 
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    mt.kind AS company_type,
    
    COUNT(DISTINCT c.id) AS total_roles,
    MAX(t.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type mt ON mc.company_type_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    aka_title t ON mh.movie_id = t.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year IS NOT NULL
GROUP BY 
    a.name, t.title, mt.kind
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    latest_movie_year DESC, 
    actor_name ASC;