WITH RECURSIVE MovieHierarchy AS (
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
        a.title as title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.id AS actor_id,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT mk.keyword) AS keywords,
    m.title AS movie_title,
    m.production_year,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS year_rank,
    COUNT(cc.id) FILTER (WHERE cc.status_id = 1) OVER (PARTITION BY a.id) AS active_roles
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id AND cc.subject_id = a.id
WHERE 
    a.name IS NOT NULL 
    AND m.production_year BETWEEN 2000 AND 2020
    AND (a.name_pcode_cf IS NOT NULL OR a.name_pcode_nf IS NOT NULL)
GROUP BY 
    a.id, m.id
ORDER BY 
    active_roles DESC, 
    m.production_year DESC
LIMIT 100;
