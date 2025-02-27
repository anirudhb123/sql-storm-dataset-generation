WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        title t ON ml.linked_movie_id = t.id
)
SELECT 
    m.title AS original_movie,
    COUNT(DISTINCT mh.linked_movie_id) AS total_linked_movies,
    MAX(mh.level) AS max_link_depth,
    AVG(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_role_emp_stats,
    STRING_AGG(DISTINCT a.name, ', ' ORDER BY a.name) AS actor_names
FROM 
    MovieHierarchy mh
JOIN 
    title m ON mh.movie_id = m.id
LEFT JOIN 
    cast_info c ON m.id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
WHERE 
    m.production_year IS NOT NULL
GROUP BY 
    m.title
HAVING 
    COUNT(DISTINCT mh.linked_movie_id) > 0
ORDER BY 
    total_linked_movies DESC, max_link_depth ASC;
