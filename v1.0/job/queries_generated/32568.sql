WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
)
SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    h.level,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors
FROM 
    movie_hierarchy AS h
LEFT JOIN 
    complete_cast AS cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS ci ON ci.movie_id = h.movie_id
LEFT JOIN 
    aka_name AS ak ON ak.person_id = ci.person_id
WHERE 
    h.production_year IS NOT NULL
GROUP BY 
    h.movie_id, h.title, h.production_year, h.level
ORDER BY 
    h.production_year DESC, actor_count DESC
LIMIT 50;

This SQL query performs the following:

1. A Common Table Expression (CTE) called `movie_hierarchy` recursively finds movies and their linked movies based on the `movie_link` table.
2. The main query selects various attributes from `movie_hierarchy`, including the count of distinct actors and a concatenated list of their names.
3. It uses outer joins (`LEFT JOIN`) to gather information from related tables such as `complete_cast`, `cast_info`, and `aka_name`.
4. The results are filtered to only include entries with a non-null production year and groups outputs by movie attributes.
5. Finally, the results are ordered by production year and actor count, limiting the output to the top 50 entries.
