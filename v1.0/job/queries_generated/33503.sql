WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1 -- Assuming 1 represents movies in the kind_type table

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    p.name AS actor_name,
    m.title AS movie_title,
    string_agg(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) AS cast_count,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS average_notes,
    MAX(m.production_year) AS last_production_year,
    MIN(m.production_year) AS first_production_year,
    SUM(CASE WHEN m.production_year >= 2000 THEN 1 ELSE 0 END) AS modern_movies,
    ARRAY_AGG(DISTINCT c.role_id) AS role_ids ON (c.nr_order IS NOT NULL)
FROM 
    aka_name p
JOIN 
    cast_info c ON p.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = c.movie_id
WHERE 
    p.name IS NOT NULL 
    AND m.production_year IS NOT NULL 
GROUP BY 
    p.name, m.title
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    average_notes DESC, modern_movies DESC, last_production_year DESC;

In this SQL query, we have included a recursive CTE to explore movie connections, extracted several fields with aggregate functions (like `COUNT`, `AVG`, `SUM`, `ARRAY_AGG`, etc.), performed outer joins for keywords, and handled NULL logic in calculations. The query examines actors' contributions to movies and calculates related metrics, providing a comprehensive performance benchmarking structure.
