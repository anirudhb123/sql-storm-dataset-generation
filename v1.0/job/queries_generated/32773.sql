WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies
    SELECT 
        mt.title,
        mt.production_year,
        mt.id AS movie_id,
        1 AS level
    FROM 
        aka_title mt
    
    UNION ALL
    
    -- Recursive case: Get linked movies
    SELECT 
        at.title,
        at.production_year,
        ml.linked_movie_id AS movie_id,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies_count,
    STRING_AGG(DISTINCT c.kind ORDER BY c.kind) AS company_types,
    AVG(pi.age) AS average_age,
    SUM(CASE WHEN pi.info LIKE '%award%' THEN 1 ELSE 0 END) AS awards_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS ranking
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    mh.level <= 3 
    AND mh.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ak.name, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    ranking, mh.production_year DESC;
