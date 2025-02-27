WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name,
    ak.id,
    COUNT(DISTINCT cc.movie_id) AS total_movies,
    AVG(mh.level) AS average_link_level,
    STRING_AGG(DISTINCT mt.title, ', ') AS linked_movies,
    CASE 
        WHEN AVG(mh.level) IS NULL THEN 'N/A'
        ELSE CAST(AVG(mh.level) AS VARCHAR)
    END AS average_level_display
FROM 
    aka_name ak
LEFT JOIN 
    cast_info cc ON ak.person_id = cc.person_id
LEFT JOIN 
    movie_hierarchy mh ON cc.movie_id = mh.movie_id
JOIN 
    aka_title mt ON cc.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND mt.production_year IS NOT NULL
GROUP BY 
    ak.name, ak.id
HAVING 
    COUNT(DISTINCT cc.movie_id) > 5
ORDER BY 
    total_movies DESC;
