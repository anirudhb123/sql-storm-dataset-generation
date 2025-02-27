WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m2.id AS movie_id,
        m2.title,
        m2.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT cf.person_id) AS num_cast_members,
    SUM(CASE 
            WHEN cf.note IS NULL THEN 1 
            ELSE 0 
        END) AS num_unnamed_cast
FROM 
    aka_name a
JOIN 
    cast_info cf ON a.person_id = cf.person_id
JOIN 
    title t ON cf.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
WHERE 
    a.name IS NOT NULL AND
    t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 3
ORDER BY 
    t.production_year DESC, 
    num_cast_members DESC
LIMIT 10;

-- Fetch a comprehensive set of information showcasing actors, movies, and their relationships
-- Focused on more recent films with considerable cast sizes and keyword diversity
