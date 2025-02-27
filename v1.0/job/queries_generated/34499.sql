WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        at.production_year >= 2000
)
SELECT 
    a.id AS actor_id,
    an.name AS actor_name,
    mh.movie_id,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    SUM(CASE WHEN mt.kind_id IN (1, 2) THEN 1 ELSE 0 END) AS total_movies,
    ROW_NUMBER() OVER(PARTITION BY an.id ORDER BY mh.production_year DESC) AS movie_rank
FROM 
    cast_info ci
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') 
    AND (mi.info IS NOT NULL AND mi.info::numeric > 1000000)
GROUP BY 
    an.id, an.name, mh.movie_id, mh.title, mh.production_year
HAVING 
    total_companies > 0
ORDER BY 
    movie_rank, actor_name;
