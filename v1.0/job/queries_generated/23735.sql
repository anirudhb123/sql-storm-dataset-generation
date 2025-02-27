WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year::text, 'Unknown') AS production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.id IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        COALESCE(at.production_year::text, 'Unknown') AS production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    ARRAY_AGG(DISTINCT mh.title ORDER BY mh.level) AS related_movies,
    COALESCE(SUM(CASE 
                    WHEN ci.note IS NOT NULL AND ci.note NOT LIKE '%extra%' THEN 1 
                    ELSE NULL 
                 END), 0) AS principal_roles,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(mh.movie_id) DESC) AS movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
WHERE 
    ak.name IS NOT NULL
    AND mh.level <= 3
    AND ak.id IS NOT NULL
    AND ak.md5sum IS NOT NULL
GROUP BY 
    ak.id, ak.name
ORDER BY 
    movie_rank;

This SQL query performs a complex operation by utilizing a recursive common table expression (CTE) to form a hierarchy of movies related through links. It aggregates actor names, their associated movies, counts their principal roles while avoiding extra roles, and counts associated keywords. It also safely handles NULLs and employs window functions to rank the actors based on the number of movies they are related to. The complexity arises with various join types, string expressions, aggregations, and predicates, making it suitable for performance benchmarking.
