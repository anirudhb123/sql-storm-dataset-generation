WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000 -- Start from the year 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3 -- Limit depth of recursive search
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(info_length) AS average_info_length,
    MIN(COALESCE(ci.nr_order, 999)) AS minimum_order
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
JOIN 
    (SELECT 
        movie_id,
        LENGTH(info) AS info_length
     FROM 
        movie_info
     WHERE 
        info_type_id IN (SELECT id FROM info_type WHERE info = 'Summary')
    ) AS movie_summary ON t.id = movie_summary.movie_id
JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 5
ORDER BY 
    average_info_length DESC,
    minimum_order ASC
LIMIT 50;
