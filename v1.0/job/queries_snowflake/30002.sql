
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'film')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON at.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy AS mh ON mh.movie_id = ml.movie_id
)
SELECT 
    ak.name AS actor_name,
    ARRAY_TO_STRING(ARRAY_AGG(DISTINCT mh.title), ', ') AS linked_movies,
    COUNT(DISTINCT mh.movie_id) AS total_linked_movies,
    SUM(CASE WHEN mh.level = 1 THEN 1 ELSE 0 END) AS root_movies,
    AVG(COALESCE(LENGTH(ak.name), 0)) AS avg_actor_name_length
FROM 
    cast_info AS ci
JOIN 
    aka_name AS ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_hierarchy AS mh ON mh.movie_id = ci.movie_id
WHERE 
    ci.nr_order <= (
        SELECT 
            COUNT(*) 
        FROM 
            cast_info AS ci2 
        WHERE 
            ci2.movie_id = ci.movie_id
        AND 
            ci2.nr_order < ci.nr_order
    )
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 2
ORDER BY 
    avg_actor_name_length DESC
LIMIT 10;
