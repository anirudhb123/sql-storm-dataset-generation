WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Start with all movies
    SELECT 
        ak.id AS movie_id,
        ak.title,
        ak.production_year,
        0 AS level
    FROM 
        aka_title ak
    WHERE 
        ak.production_year >= 2000

    UNION ALL

    -- Recursive case: Find sequels or related movies
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ml.linked_movie_id) AS related_movies_count,
    SUM(CASE WHEN ak.name IS NULL THEN 1 ELSE 0 END) AS null_actor_count,
    AVG(CASE WHEN ak.name IS NOT NULL AND mh.level = 1 THEN 1 ELSE 0 END) AS avg_direct_related
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_link ml ON mh.movie_id = ml.movie_id
WHERE 
    mh.production_year > 2010
GROUP BY 
    ak.name, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ml.linked_movie_id) > 1
ORDER BY 
    movie_title;
