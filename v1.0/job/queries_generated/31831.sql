WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id as movie_id,
        mt.title,
        mt.production_year,
        NULL::integer as parent_id,
        1 as level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        at.title, 
        at.production_year, 
        mh.movie_id,
        level + 1
    FROM 
        movie_link ml 
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    a.name AS main_actor,
    (SELECT COUNT(*) 
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id = mh.movie_id) AS keyword_count,
    COALESCE(NULLIF(a.surname_pcode, ''), 'UNKNOWN') AS surname_code,
    AVG(CASE WHEN coalesce(ci.role_id, 0) = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY mh.movie_id) AS actor_role_ratio
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
WHERE 
    mh.level = 1 
    AND mh.production_year > 2000
    AND (a.name IS NOT NULL OR mh.title IS NOT NULL)
ORDER BY 
    mh.production_year DESC, mh.title;
