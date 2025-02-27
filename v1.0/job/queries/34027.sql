WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    p.name AS person_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    AVG(CASE WHEN c.nr_order IS NULL THEN 0 ELSE c.nr_order END) AS avg_cast_order,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    MAX(mh.level) AS max_link_level
FROM 
    aka_name p
LEFT JOIN 
    cast_info c ON p.person_id = c.person_id
LEFT JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
WHERE 
    p.name IS NOT NULL
    AND t.production_year IS NOT NULL
    AND (t.title ILIKE '%action%' OR t.title ILIKE '%drama%')
GROUP BY 
    p.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    movie_count DESC,
    person_name ASC;
