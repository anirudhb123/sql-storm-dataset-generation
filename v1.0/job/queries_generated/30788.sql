WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        m.title, 
        m.production_year, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN CAST(mi.info AS DECIMAL) ELSE NULL END) AS average_budget,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS production_rank
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.production_year IS NOT NULL
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, mh.movie_id, mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    mh.production_year DESC, production_rank, ak.name;
