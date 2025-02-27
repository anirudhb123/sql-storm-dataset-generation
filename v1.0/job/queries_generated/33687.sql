WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
 
    UNION ALL
 
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mv.title AS movie_title,
    mv.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    MAX(CASE WHEN i.info_type_id = 1 THEN i.info END) AS genre,
    MAX(CASE WHEN i.info_type_id = 2 THEN i.info END) AS rating,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
    SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS company_count
FROM 
    movie_hierarchy mv
LEFT JOIN 
    cast_info c ON mv.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_info i ON mv.movie_id = i.movie_id
LEFT JOIN 
    movie_companies mc ON mv.movie_id = mc.movie_id
WHERE 
    mv.depth <= 2
GROUP BY 
    mv.movie_id, mv.title, mv.production_year
ORDER BY 
    actor_count DESC,
    avg_order
LIMIT 10;
