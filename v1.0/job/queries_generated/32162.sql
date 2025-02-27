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
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    SUM(CASE WHEN co.country_code IS NULL THEN 1 ELSE 0 END) AS null_country_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    mh.production_year > 2000
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    total_cast DESC, mh.production_year ASC
LIMIT 100;
