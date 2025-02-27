WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.episode_of_id, mt.id) AS root_movie_id,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.root_movie_id,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title lt ON ml.linked_movie_id = lt.id
    JOIN
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    a.name AS actor_name,
    COUNT(dc.movie_id) AS total_movies,
    SUM(CASE WHEN dc.production_year = 2021 THEN 1 ELSE 0 END) AS movies_in_2021,
    AVG(dd.depth) AS avg_movie_depth,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    movie_hierarchy dd ON ci.movie_id = dd.movie_id
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    aka_title dc ON ci.movie_id = dc.id
WHERE 
    a.name IS NOT NULL
    AND (dc.production_year IS NOT NULL OR dc.production_year > 1990)
    AND a.name NOT LIKE 'Unknown%'
GROUP BY 
    a.name
HAVING 
    COUNT(dc.movie_id) > 5
ORDER BY 
    total_movies DESC;
