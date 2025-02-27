WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000 -- starting point for recursion

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(CASE WHEN info.info_type_id = 1 THEN 1 ELSE 0 END) AS avg_info_type_1,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count,
    COUNT(DISTINCT mh.movie_id) AS associated_movies_count
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    movie_companies m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_info info ON info.movie_id = c.movie_id
LEFT JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = c.movie_id
WHERE 
    a.name IS NOT NULL 
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 10
ORDER BY 
    movie_count DESC;
