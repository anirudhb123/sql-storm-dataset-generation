WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ka.name AS actor_name,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    MAX(CASE WHEN mt.production_year IS NOT NULL THEN mt.production_year ELSE 0 END) AS latest_movie_year,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles,
    ROW_NUMBER() OVER (PARTITION BY ka.name ORDER BY MAX(mt.production_year) DESC) AS actor_rank
FROM 
    aka_name ka
LEFT JOIN 
    cast_info ci ON ka.person_id = ci.person_id
LEFT JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    ka.name IS NOT NULL
    AND (mt.production_year IS NULL OR mt.production_year >= 2000)
GROUP BY 
    ka.name
HAVING 
    COUNT(DISTINCT mt.id) > 5
ORDER BY 
    actor_rank, keyword_count DESC;
