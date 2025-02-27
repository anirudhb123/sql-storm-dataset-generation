WITH RECURSIVE movie_hierarchy AS (
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
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.id AS actor_id,
    a.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    AVG(CASE WHEN yt.kind_id = 1 THEN 1 ELSE NULL END) AS avg_main_roles,
    STRING_AGG(DISTINCT DISTINCT mt.title, ', ') AS titles,
    STRING_AGG(DISTINCT mt.production_year::text, ', ') AS production_years,
    COUNT(DISTINCT CASE WHEN mt.production_year IS NULL THEN 0 END) AS null_production_years
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mi ON mc.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON mc.movie_id = mk.movie_id
LEFT JOIN 
    kind_type yt ON yt.id = mi.info_type_id
LEFT JOIN 
    movie_hierarchy mt ON mc.movie_id = mt.movie_id
WHERE 
    a.name ILIKE '%john%'
    AND ci.nr_order = 1
GROUP BY 
    a.id, a.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    total_movies DESC;
