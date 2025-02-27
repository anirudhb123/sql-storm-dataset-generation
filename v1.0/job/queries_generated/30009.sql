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
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    akn.name AS actor_name,
    at.title AS movie_title,
    mh.level AS movie_level,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    SUM(CASE 
            WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN CAST(mi.info AS FLOAT)
            ELSE 0 
        END) AS total_rating,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MAX(CASE 
            WHEN c.person_role_id IS NULL THEN 'N/A'
            ELSE r.role 
        END) AS role_description
FROM 
    cast_info c
JOIN 
    aka_name akn ON c.person_id = akn.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title at ON mh.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    mh.production_year > 2000
GROUP BY 
    akn.name, at.title, mh.level
HAVING 
    COUNT(DISTINCT mc.company_id) > 2
ORDER BY 
    movie_level ASC, total_rating DESC;
