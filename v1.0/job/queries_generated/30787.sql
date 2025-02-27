WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        production_year >= 2000  
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
info_summary AS (
   SELECT 
       mi.movie_id,
       STRING_AGG(CASE WHEN it.info = 'Genre' THEN mi.info ELSE NULL END, ', ') AS genres,
       STRING_AGG(CASE WHEN it.info = 'Director' THEN mi.info ELSE NULL END, ', ') AS directors
   FROM 
       movie_info mi
   JOIN 
       info_type it ON mi.info_type_id = it.id
   GROUP BY 
       mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cs.total_cast,
    cs.cast_names,
    is.genres,
    is.directors,
    CASE 
        WHEN mh.depth > 1 THEN 'Linked Movie'
        ELSE 'Original Movie'
    END AS movie_type
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    info_summary is ON mh.movie_id = is.movie_id
ORDER BY 
    mh.production_year DESC, mh.title ASC;
