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
        mt.title,
        mt.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    mh.level AS movie_level,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(length(m.info)) AS avg_info_length,
    SUM(CASE WHEN p.info IS NOT NULL THEN 1 ELSE 0 END) AS person_info_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_info m ON at.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
LEFT JOIN 
    person_info p ON ci.person_id = p.person_id
WHERE 
    at.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, at.title, mh.level
ORDER BY 
    company_count DESC, avg_info_length DESC
LIMIT 50;
