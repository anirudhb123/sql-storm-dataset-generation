WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        ak.title,
        ak.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    STRING_AGG(DISTINCT mh.title, ', ') AS movies,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    MAX(mh.production_year) AS last_movie_year
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    a.name IS NOT NULL
    AND mh.depth <= 3
    AND (rt.role = 'Actor' OR rt.role IS NULL)
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 10
ORDER BY 
    last_movie_year DESC;
