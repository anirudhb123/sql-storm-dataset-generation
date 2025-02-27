WITH RECURSIVE movie_hierarchy AS (
    -- Recursive CTE to gather movie relationships for all linked movies
    SELECT 
        m.id AS movie_id,
        m.title,
        ml.linked_movie_id,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id

    UNION ALL

    SELECT 
        m.id,
        m.title,
        ml.linked_movie_id,
        level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title m ON mh.linked_movie_id = m.id
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
)
SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    AVG(cast.nr_order) AS average_order,
    COUNT(DISTINCT mh.linked_movie_id) AS linked_movies_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    COUNT(DISTINCT ci.movie_id) AS movies_count,
    COALESCE(NULLIF(ROUND(AVG(m.production_year), 0), 0), 'Unknown') AS avg_production_year,
    COUNT(DISTINCT pi.info) FILTER (WHERE pi.info IS NOT NULL) AS info_available_count
FROM 
    aka_name a
LEFT JOIN 
    cast_info cast ON a.person_id = cast.person_id
LEFT JOIN 
    aka_title at ON cast.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON at.id = cc.movie_id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = at.id
WHERE 
    a.name IS NOT NULL
    AND (cast.nr_order > 0 OR cast.nr_order IS NULL) 
    AND at.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, at.title
HAVING 
    COUNT(DISTINCT at.id) > 2 
    AND AVG(cast.nr_order) > 1
ORDER BY 
    average_order DESC, 
    linked_movies_count DESC;
