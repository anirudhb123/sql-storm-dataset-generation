WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || m.title AS VARCHAR(255))
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title m ON mh.movie_id = m.episode_of_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    mh.path AS movie_path,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY m.production_year DESC) AS actor_movie_rank,
    COUNT(DISTINCT c.movie_id) OVER (PARTITION BY a.name) AS total_movies,
    COALESCE(k.keyword, 'No Keywords') AS movie_keyword,
    m.production_year 
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    MovieHierarchy mh ON mh.movie_id = m.id
WHERE 
    m.production_year IS NOT NULL
    AND a.name IS NOT NULL
    AND m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
    AND EXTRACT(YEAR FROM CURRENT_DATE) - m.production_year < 10
ORDER BY 
    actor_movie_rank, m.production_year DESC
OFFSET 5 LIMIT 10;

-- This complex query performs the following:
-- - It creates a recursive CTE to build a hierarchy of movies for certain titles released after the year 2000.
-- - It then retrieves the actor names, the titles of those movies, hierarchical paths of the movie structures, 
--   and filters based on the movie type while also managing NULLs.
-- - The query calculates the rank of movies for each actor, the total count of movies, and lists keywords if available, providing a robust performance benchmark for the query execution plan. 
