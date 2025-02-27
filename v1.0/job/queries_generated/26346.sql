WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id

    UNION ALL 

    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.movie_id
    JOIN 
        movie_hierarchy mh ON mh.linked_movie_id = mt.id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    mh.depth,
    COUNT(DISTINCT mh.linked_movie_id) AS related_movies_count,
    ARRAY_AGG(DISTINCT at.title) AS related_movies_titles
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name ILIKE '%Smith%' -- Example filter for actor's name
GROUP BY 
    ak.name, at.title, mh.production_year, mh.depth
ORDER BY 
    mh.production_year DESC, related_movies_count DESC;
