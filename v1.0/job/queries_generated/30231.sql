WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2020  -- Start with movies from the year 2020

    UNION ALL

    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        h.level + 1
    FROM 
        movie_link m
    JOIN 
        MovieHierarchy h ON m.linked_movie_id = h.movie_id
    WHERE 
        h.level < 3  -- Limit depth to 3 levels
)

SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    CASE 
        WHEN c.nr_order IS NULL THEN 'Unknown Role'
        ELSE rt.role
    END AS role,
    COALESCE(ci.note, 'No additional notes') AS cast_note,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY mt.production_year DESC) AS movie_rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    MovieHierarchy mt ON c.movie_id = mt.movie_id
LEFT JOIN 
    role_type rt ON c.role_id = rt.id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
WHERE 
    mt.production_year BETWEEN 2015 AND 2020
GROUP BY 
    a.id, mt.id, rt.role, ci.note
HAVING 
    COUNT(DISTINCT kc.keyword) >= 3  -- Only include actors/movies with at least 3 unique keywords
ORDER BY 
    actor_name,
    movie_rank;
