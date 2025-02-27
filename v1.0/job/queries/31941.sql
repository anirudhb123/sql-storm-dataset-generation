WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2020
    
    UNION ALL
    
    SELECT 
        mv.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        movie_link mv
    JOIN 
        aka_title mt ON mv.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON mv.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(cast_info.nr_order, 0) AS cast_order,
    STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') AS cast_names,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mh.movie_id) AS keyword_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mh.movie_id) AS info_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ON mh.movie_id = cast_info.movie_id
LEFT JOIN 
    aka_name a ON cast_info.person_id = a.person_id
LEFT JOIN 
    role_type r ON cast_info.role_id = r.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, cast_info.nr_order
ORDER BY 
    mh.production_year DESC, mh.level, cast_order;