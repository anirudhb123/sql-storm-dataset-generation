WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::text AS parent_title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.title AS parent_title,
        level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.movie_id
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.parent_title,
    mh.level,
    COUNT(ci.id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(CASE WHEN (mi.info_type_id IS NULL) THEN 0 ELSE 1 END) AS average_info_existence,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level <= 2
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.parent_title, mh.level
ORDER BY 
    mh.production_year DESC, cast_count DESC
LIMIT 100;
