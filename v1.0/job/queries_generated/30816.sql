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
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT cc.role_id) AS num_roles,
    STRING_AGG(DISTINCT cct.kind, ', ') AS company_kinds,
    SUM(CASE WHEN mp.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY COUNT(DISTINCT cc.role_id) DESC) AS actor_ranking
FROM 
    aka_name ak
JOIN 
    cast_info cc ON ak.person_id = cc.person_id
JOIN 
    complete_cast cct ON cc.movie_id = cct.movie_id
JOIN 
    movie_companies mc ON cct.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mp ON cct.movie_id = mp.movie_id AND mp.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
JOIN 
    MovieHierarchy mh ON cct.movie_id = mh.movie_id
GROUP BY 
    ak.id, mt.title, mh.production_year
HAVING 
    COUNT(DISTINCT cc.role_id) >= 2
ORDER BY 
    actor_ranking;
