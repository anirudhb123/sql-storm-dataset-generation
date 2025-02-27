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
        ml.linked_movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    COUNT(DISTINCT k.id) AS total_keywords,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_cast_order,
    ARRAY_AGG(DISTINCT a.name) FILTER (WHERE a.name IS NOT NULL) AS actor_names
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    mh.production_year DESC, avg_cast_order DESC
LIMIT 50;
