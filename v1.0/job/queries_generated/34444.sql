WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level,
        CAST(t.title AS VARCHAR(255)) AS path
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1,
        CAST(mh.path || ' > ' || m.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.kind_id,
    mh.level,
    mh.path,
    COALESCE(ki.keyword, 'Unknown') AS keyword,
    ARRAY_AGG(DISTINCT CONCAT(a.name, ' as ', rt.role)) AS cast_roles,
    AVG(mi.info::NUMERIC) FILTER (WHERE it.info = 'rating') AS average_rating,
    COUNT(DISTINCT mi.info_type_id) AS total_info_types
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    role_type rt ON c.role_id = rt.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.kind_id, mh.level, mh.path, ki.keyword
ORDER BY 
    mh.production_year DESC, mh.level, mh.title;

