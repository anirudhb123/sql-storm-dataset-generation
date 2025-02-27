WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        mt.production_year
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
      
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.level + 1,
        at.production_year
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    MAX(mh.production_year) AS last_movie_year,
    STRING_AGG(DISTINCT mh.movie_title, ', ') AS movie_titles,
    AVG(DATEDIFF('year', mh.production_year, CURRENT_DATE)) AS avg_years_since_release
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    total_movies DESC
LIMIT 10;

-- Performance benchmarks could include execution time, execution plan details,
-- and respective counts for different join operations and CTEs measured against 
-- other simpler queries for comparison.
