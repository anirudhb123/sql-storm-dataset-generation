WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020

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
    mt.title AS movie_title,
    COALESCE(co.name, 'Unknown Company') AS production_company,
    COUNT(DISTINCT cc.subject_id) AS total_cast,
    AVG(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS male_ratio,
    RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.subject_id) DESC) AS rank_by_cast
FROM 
    complete_cast cc
JOIN 
    aka_title mt ON cc.movie_id = mt.id
JOIN 
    cast_info ci ON cc.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mt.id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    mh.level = 1 
    AND (p.info IS NULL OR p.info NOT LIKE '%uncredited%')
GROUP BY 
    ak.name, mt.title, co.name, mt.production_year
HAVING 
    COUNT(DISTINCT cc.subject_id) >= 5
ORDER BY 
    rank_by_cast, movie_title;
