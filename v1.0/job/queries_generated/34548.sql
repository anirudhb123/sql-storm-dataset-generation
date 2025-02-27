WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        lt.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
    WHERE 
        lt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
)

SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    COUNT(mc.company_id) AS company_count,
    MAX(mi.info) AS highlight_info,
    SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') THEN CAST(mi.info AS INTEGER) ELSE 0 END) AS total_budget,
    RANK() OVER (PARTITION BY ak.id ORDER BY mt.production_year DESC) AS rank_by_year
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    ak.name IS NOT NULL
    AND mh.level <= 2
GROUP BY 
    ak.id, mt.movie_title
HAVING 
    COUNT(mc.company_id) > 0
ORDER BY 
    actor_name, total_budget DESC;
