WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        md5sum
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1 AS depth,
        mt.md5sum
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    MAX(mh.production_year) AS last_movie_year,
    STRING_AGG(DISTINCT mh.title, ', ') AS movie_titles,
    AVG(mth.depth) FILTER (WHERE mth.depth IS NOT NULL) AS average_depth
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN (
    SELECT 
        mv.movie_id,
        depth
    FROM 
        movie_hierarchy mv
    WHERE 
        depth <= 3
) mth ON mth.movie_id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 3
ORDER BY 
    total_movies DESC
FETCH FIRST 10 ROWS ONLY;

-- Additionally, check for NULL logic for actors with no associated movies
SELECT 
    ak.name AS actor_name,
    COALESCE(COUNT(ci.movie_id), 0) AS associated_movies
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
GROUP BY 
    ak.name
HAVING 
    COALESCE(COUNT(ci.movie_id), 0) = 0
ORDER BY 
    ak.name;
