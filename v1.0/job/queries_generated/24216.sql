WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Base case: get top-level movies without episodes

    UNION ALL

    SELECT 
        et.id AS movie_id, 
        et.title AS movie_title, 
        et.production_year, 
        mh.depth + 1
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id  -- Recursive case: join episodes to their parent
)

SELECT 
    ak.name AS actor_name,
    COALESCE(mt.movie_title, 'None') AS movie_title,
    CASE 
        WHEN mt.depth IS NULL THEN 'Not Part of a Series'
        ELSE 'Part of a Series (Depth: ' || mt.depth || ')'
    END AS series_info,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    SUM(CASE 
        WHEN mpi.info_type_id IS NOT NULL THEN 1
        ELSE 0 
    END) AS info_count,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT kw.keyword) DESC) AS actor_keyword_rank
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_hierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_keyword mw ON mt.movie_id = mw.movie_id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
LEFT JOIN 
    movie_info mpi ON mt.movie_id = mpi.movie_id AND mpi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('BoxOffice', 'AudienceScore'))  -- Targeted info types
WHERE 
    ak.name IS NOT NULL
    AND ak.md5sum IS NOT NULL  -- Ensure we are only considering valid entries
GROUP BY 
    ak.name, mt.movie_title, mt.depth
HAVING 
    COUNT(DISTINCT kw.keyword) > 0 -- Only consider actors with associated keywords
ORDER BY 
    actor_keyword_rank;

This query leverages Common Table Expressions (CTEs) to build a recursive hierarchy of movies and their episodes, performs outer joins to gather related data, aggregates keyword counts, and employs window functions for ranking. The use of `COALESCE`, `CASE`, and complex joins provides a thorough and interesting benchmark query. The logic around info counts and the depth of series adds additional complexity to the result set, making it suitable for performance benchmarking.
