WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS TEXT) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || m.title AS TEXT)
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    AVG(mh.level) AS avg_link_level,
    STRING_AGG(DISTINCT mh.path, ', ') AS movie_paths,
    MAX(t.production_year) AS latest_movie_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
    AND mh.movie_id IS NULL  -- Finding actors without any linked movie
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    movie_count DESC, avg_link_level ASC;

-- The query aggregates actor data, determining their movie count, linked movie path levels, 
-- and the latest production year of their movies, while incorporating both recursive joins 
-- to trace linked movies and outer joins to capture actors with no links. 
