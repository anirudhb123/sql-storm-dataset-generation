WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS text) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || mt.title AS text)
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.path,
    mh.production_year,
    COUNT(DISTINCT ca.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    AVG(mo.info_length) AS average_info_length
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.id
LEFT JOIN 
    aka_name ak ON ca.person_id = ak.person_id
LEFT JOIN (
    SELECT 
        movie_id,
        LENGTH(info) AS info_length
    FROM 
        movie_info
    WHERE 
        info_length IS NOT NULL
) mo ON mh.movie_id = mo.movie_id
WHERE 
    mh.level <= 3
GROUP BY 
    mh.path, mh.production_year
HAVING 
    COUNT(DISTINCT ca.person_id) > 5
ORDER BY 
    mh.production_year DESC, actor_count DESC;
