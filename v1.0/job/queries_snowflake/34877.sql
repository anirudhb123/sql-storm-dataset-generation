
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year = 2023
    
    UNION ALL
    
    SELECT 
        m2.id AS movie_id,
        m2.title AS movie_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
)

, MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
)

SELECT 
    mh.movie_title,
    mh.level AS movie_level,
    COALESCE(mc.cast_count, 0) AS total_cast,
    mc.actor_names,
    COUNT(DISTINCT keyword.keyword) AS keyword_count,
    LISTAGG(DISTINCT ki.info, '; ') WITHIN GROUP (ORDER BY ki.info) AS movie_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieCast mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ON mk.keyword_id = keyword.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    info_type ki ON mi.info_type_id = ki.id
WHERE 
    mh.movie_title IS NOT NULL
GROUP BY 
    mh.movie_title, mh.level, mc.cast_count, mc.actor_names
ORDER BY 
    mh.level, mh.movie_title;
