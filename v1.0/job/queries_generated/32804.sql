WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    AVG(mt.production_year) AS average_production_year,
    RANK() OVER (ORDER BY COUNT(DISTINCT mc.movie_id) DESC) AS actor_rank,
    MAX(mh.depth) AS max_link_depth
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    aka_title mt ON mc.movie_id = mt.id
LEFT JOIN 
    movie_hierarchy mh ON mt.id = mh.movie_id
WHERE 
    mt.production_year IS NOT NULL
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 1
ORDER BY 
    actor_rank, ak.name;
