WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Filter for movies produced from 2000 onwards

    UNION ALL

    SELECT 
        m.id AS movie_id,
        CONCAT('Sequel: ', m.title) AS title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 3  -- Limit to 2 levels of sequel
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.role_id) AS role_count,
    SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS null_notes
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ak.name IS NOT NULL 
    AND mt.production_year IS NOT NULL
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT k.id) > 0  -- Only include movies with at least one keyword
ORDER BY 
    mt.production_year DESC, role_count DESC;

