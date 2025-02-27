WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN  
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy AS mh ON mh.movie_id = ml.movie_id
)
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    count(DISTINCT mc.company_id) AS production_companies,
    COUNT(DISTINCT mkw.keyword) AS keywords_count,
    RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
FROM 
    movie_companies AS mc
JOIN 
    aka_title AS t ON mc.movie_id = t.id
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword AS mkw ON mk.keyword_id = mkw.id
LEFT JOIN 
    MovieHierarchy AS mh ON mh.movie_id = t.id
WHERE
    t.production_year BETWEEN 2000 AND 2020
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    t.production_year DESC, production_companies DESC;
