WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL
        
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.level + 1 AS level
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.movie_id = at.id
    JOIN
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT
    ak.name AS actor_name,
    COUNT(DISTINCT h.movie_id) AS movies_in_hierarchy,
    STRING_AGG(DISTINCT h.movie_title || ' (' || h.production_year || ')', ', ') AS movie_list,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_notes,
    SUM(CASE 
            WHEN ci.nr_order IS NULL THEN 0 
            ELSE 1 
        END) AS valid_order_count
FROM
    aka_name ak
LEFT JOIN
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN
    MovieHierarchy h ON ci.movie_id = h.movie_id 
WHERE
    ak.name IS NOT NULL
GROUP BY
    ak.name
HAVING
    COUNT(DISTINCT h.movie_id) > 0
ORDER BY
    movies_in_hierarchy DESC;
