WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.depth + 1,
        CAST(mh.path || ' -> ' || et.title AS VARCHAR(255)) AS path
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    STRING_AGG(DISTINCT mh.path, ', ') AS movie_paths,
    AVG(CASE 
            WHEN mt.production_year IS NOT NULL THEN mt.production_year 
            ELSE NULL 
        END) AS avg_year,
    MAX(mt.production_year) AS latest_year,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(mc.movie_id) DESC) AS rank
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mi ON mc.movie_id = mi.movie_id
LEFT JOIN 
    movie_hierarchy mh ON mc.movie_id = mh.movie_id
LEFT JOIN 
    aka_title mt ON ci.movie_id = mt.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    movie_count DESC,
    rank;
