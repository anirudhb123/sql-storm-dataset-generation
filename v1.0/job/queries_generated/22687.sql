WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.title IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    MIN(mh.production_year) AS first_movie_year,
    MAX(mh.production_year) AS last_movie_year,
    AVG(mh.depth) AS avg_depth,
    STRING_AGG(DISTINCT mh.title, '; ') AS movie_titles,
    SUM(CASE WHEN mh.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'doc%') THEN 1 ELSE 0 END) AS doc_movies,
    COALESCE((SELECT COUNT(*) FROM cast_info ci WHERE ci.person_id = ak.person_id AND ci.movie_id IN (SELECT movie_id FROM movie_hierarchy)), 0) AS total_roles
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
WHERE 
    ak.name ILIKE '%smith%' 
    AND ak.md5sum IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5 
    AND AVG(mh.depth) < 2.5
ORDER BY 
    total_movies DESC, first_movie_year ASC
LIMIT 10;

-- This query creates a recursive Common Table Expression (CTE) to explore movie linkages 
-- and joins with actor details, counting movies and filtering based on performance metrics.
