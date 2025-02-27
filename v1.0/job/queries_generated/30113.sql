WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
role_counts AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
movie_info_aggregates AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Synopsis' THEN mi.info END) AS synopsis,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ri.role, 'Unknown') AS role,
    rc.role_count,
    mia.synopsis,
    mia.keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY rc.role_count DESC) AS role_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    role_counts rc ON mh.movie_id = rc.movie_id
LEFT JOIN 
    movie_info_aggregates mia ON mh.movie_id = mia.movie_id
LEFT JOIN 
    LATERAL (SELECT role FROM role_counts WHERE movie_id = mh.movie_id ORDER BY role_count DESC LIMIT 1) ri ON TRUE
WHERE 
    mh.level <= 3
ORDER BY 
    mh.production_year DESC, mh.title;
