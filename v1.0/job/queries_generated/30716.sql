WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS VARCHAR(255)) AS full_title
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1 -- Assuming '1' represents 'feature film'

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.full_title || ' -> ' || m.title AS VARCHAR(255)) AS full_title
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.full_title,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') FILTER (WHERE a.name IS NOT NULL) AS cast_names,
    AVG(COALESCE(mi.info::numeric, 0)) AS average_movie_rating,
    (SELECT 
        COUNT(DISTINCT k.id) 
     FROM 
        movie_keyword k 
     WHERE 
        k.movie_id = mh.movie_id) AS keyword_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mv.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.full_title
ORDER BY 
    mh.level, mh.production_year DESC, total_cast DESC;
