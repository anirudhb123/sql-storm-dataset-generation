WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        mk.keyword,
        1 AS depth
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        mk.keyword,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3 -- Limit recursive depth to avoid infinite loops
)

SELECT 
    mk.keyword,
    COUNT(distinct mh.movie_id) AS movie_count,
    AVG(t.production_year) AS average_production_year,
    STRING_AGG(DISTINCT a.name, '; ') AS actors,
    SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count
FROM 
    movie_hierarchy mh
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON mh.movie_id = t.id
WHERE 
    mk.keyword IS NOT NULL
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    average_production_year DESC;
