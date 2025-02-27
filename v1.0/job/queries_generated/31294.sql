WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year > 2000
        
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
        JOIN aka_title at ON ml.linked_movie_id = at.id
        JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.level < 3 -- limit depth to avoid excessive recursion
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    COUNT(*) OVER (PARTITION BY m.id) AS total_cast,
    MAX(cp.kind) AS company_type
FROM 
    MovieHierarchy m
JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_type cp ON mc.company_type_id = cp.id
WHERE 
    a.name IS NOT NULL AND 
    (m.production_year BETWEEN 2000 AND 2023) AND 
    (ci.note IS NULL OR ci.note LIKE '%lead%') -- Exclude non-lead roles if note is available
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT a.id) > 1 -- Actors who appeared in more than one movie
ORDER BY 
    m.production_year DESC, 
    a.name;
