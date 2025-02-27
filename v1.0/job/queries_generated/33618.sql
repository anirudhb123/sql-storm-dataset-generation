WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 5  -- Limit depth of recursion.
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    ATK.keyword AS movie_keyword,
    m.production_year,
    COALESCE(mh.level, -1) AS movie_level,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(pi.info_length) AS average_info_length
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword ATK ON mk.keyword_id = ATK.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
LEFT JOIN 
    (SELECT 
         movie_id,
         LENGTH(info) AS info_length
     FROM 
         movie_info WHERE note IS NOT NULL) pi ON at.id = pi.movie_id
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND at.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ak.name, at.title, ATK.keyword, m.production_year, mh.level
ORDER BY 
    actor_name, movie_title;

