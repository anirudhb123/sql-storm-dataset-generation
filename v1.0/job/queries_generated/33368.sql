WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title AS movie_title,
        et.production_year,
        mh.level + 1,
        CAST(mh.path || ' > ' || et.title AS VARCHAR(255)) AS path
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id
)
SELECT 
    m.movie_title,
    m.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast,
    MAX(CASE WHEN mp.info_type_id = 1 THEN mp.info END) AS genre,
    AVG(CASE WHEN mp.info_type_id = 2 THEN mp.info::FLOAT END) AS average_rating,
    MAX(mh.path) AS hierarchy_path
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_info mp ON mh.movie_id = mp.movie_id
WHERE 
    mh.level = (SELECT MAX(level) FROM MovieHierarchy)
GROUP BY 
    m.movie_title, m.production_year
ORDER BY 
    actor_count DESC, m.production_year DESC
LIMIT 10;
