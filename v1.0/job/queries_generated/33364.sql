WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Filter for movies post-2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        CONCAT(m.title, ' (Sequel to: ', mh.title, ')') AS title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(c.id) AS num_roles,
    AVG(pi.info) AS avg_rating -- Assuming pi.info contains numeric ratings
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    person_info pi ON pi.person_id = a.person_id 
    AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')  -- Filter for rating info
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = t.id
WHERE 
    t.production_year BETWEEN 2010 AND 2020
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(c.id) > 1  -- More than 1 role per actor
ORDER BY 
    avg_rating DESC NULLS LAST,  -- Order by average rating, ignoring NULLs at the end
    num_roles DESC;
