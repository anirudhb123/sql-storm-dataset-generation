WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title at ON m.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
)
, CastRoles AS (
    SELECT 
        ci.movie_id,
        c.role_id,
        r.role,
        COUNT(*) AS num_roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, c.role_id, r.role
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cr.role, 'Unknown Role') AS role,
    COALESCE(cr.num_roles, 0) AS total_roles,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mh.movie_id) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS row_num,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Year Unknown' 
        ELSE mh.production_year::text 
    END AS display_year
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastRoles cr ON mh.movie_id = cr.movie_id
ORDER BY 
    mh.production_year DESC NULLS LAST, 
    mh.title;
