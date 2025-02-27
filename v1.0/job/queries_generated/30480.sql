WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
        
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1,
        CAST(mh.path || ' -> ' || m.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    ARRAY_AGG(DISTINCT mh.path) AS linked_movies,
    COUNT(DISTINCT mh.movie_id) AS total_linked_movies,
    AVG(CASE 
            WHEN mh.kind_id IS NOT NULL THEN 1
            ELSE 0 
        END) AS average_kind_presence
FROM 
    movie_hierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    total_linked_movies DESC;
