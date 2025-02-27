WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        ARRAY[mt.id] AS path
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1,
        mh.path || et.id
    FROM aka_title et
    JOIN movie_hierarchy mh ON et.episode_of_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(CASE 
            WHEN mi.info_type_id IS NOT NULL THEN 1 
            ELSE 0 
        END) AS avg_movie_info,
    MAX(mh.production_year) AS latest_production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    ak.name IS NOT NULL
    AND mh.level <= 2
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    latest_production_year DESC;
