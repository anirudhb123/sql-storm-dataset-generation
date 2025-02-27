WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Starting from movies produced in the year 2000.

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5  
)

SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    AVG(mi.info::numeric) AS average_rating,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT cc.role_id) AS unique_roles,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY AVG(mi.info::numeric) DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON at.id = cc.movie_id
WHERE 
    a.name IS NOT NULL 
    AND at.production_year >= 2000 
    AND a.name NOT LIKE '%unknown%'  
GROUP BY 
    a.name, at.title, at.production_year
HAVING 
    AVG(mi.info::numeric) IS NOT NULL
ORDER BY 
    average_rating DESC, 
    actor_name ASC;

-- End of the query
