WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year AS year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    AVG(pi.info NOT LIKE '%unknown%') AS avg_person_info_validity,
    SUM(CASE WHEN kay.keyword IS NOT NULL THEN 1 ELSE 0 END) AS num_keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mh.production_year DESC) AS actor_movie_rank
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kay ON mk.keyword_id = kay.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    mh.level <= 3 
    AND (pi.info IS NULL OR pi.info LIKE '%actor%')
GROUP BY 
    ak.name, at.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1 
ORDER BY 
    actor_name, year DESC;
