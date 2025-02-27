WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.level,
    COALESCE(count(ci.id), 0) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(CASE WHEN mt.info_type_id IS NOT NULL THEN 1 ELSE NULL END) AS avg_movie_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mt ON mh.movie_id = mt.movie_id
WHERE 
    mh.production_year = (
        SELECT MAX(mh2.production_year) 
        FROM MovieHierarchy mh2 
        WHERE mh2.movie_id = mh.movie_id
    )
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT ci.id) > 3
ORDER BY 
    mh.production_year DESC, mh.level;
