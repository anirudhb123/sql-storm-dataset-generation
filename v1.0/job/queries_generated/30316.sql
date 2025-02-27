WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1 -- Assuming 1 refers to 'movie'

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    ak.name AS actor_name,
    COALESCE(ka.title, 'N/A') AS movie_title,
    mh.title AS linked_title,
    mh.production_year AS linked_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mh.production_year DESC) AS movie_ranking
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    aka_title ka ON ci.movie_id = ka.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = ka.id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = ci.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> '' 
    AND mh.level < 3
GROUP BY 
    ak.name,
    ka.title,
    mh.title,
    mh.production_year
ORDER BY 
    ak.name,
    movie_ranking;

This query uses a recursive CTE (`movie_hierarchy`) to recursively link movies based on their relationships from the `movie_link` table. It retrieves actor names, movie titles, linked movie titles, and their production years, counts distinct movie keywords, evaluates the ratio of entries with notes in the `cast_info` table, and ranks movies for each actor. The use of various join types, NULL handling, and window functions contributes to a complex and potentially interesting dataset for benchmarking performance.

