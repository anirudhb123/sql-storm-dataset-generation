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
        mt.title,
        mt.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    mk.keyword AS keyword,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(CASE WHEN ci.person_role_id IN (SELECT id FROM role_type WHERE role LIKE 'Actor%') THEN 1 ELSE 0 END) AS average_actor_roles,
    STRING_AGG(DISTINCT co.company_name, ', ') AS companies_involved,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY mh.production_year DESC) AS movie_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    MovieHierarchy mh ON cc.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
    AND (ci.note IS NULL OR ci.note NOT LIKE '%uncredited%')
GROUP BY 
    a.id, mk.keyword, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.movie_id) > 3
ORDER BY 
    total_movies DESC, average_actor_roles DESC;
