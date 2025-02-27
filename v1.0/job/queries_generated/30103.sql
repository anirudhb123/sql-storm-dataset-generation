WITH RECURSIVE movie_hierarchy AS (
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
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
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
company_summary AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_information
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(rc.role, 'Unknown Role') AS role,
    COALESCE(rc.role_count, 0) AS number_of_roles,
    cs.company_name,
    cs.company_type,
    cs.company_count,
    mis.movie_information
FROM 
    movie_hierarchy mh
LEFT JOIN 
    role_counts rc ON mh.movie_id = rc.movie_id
LEFT JOIN 
    company_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movie_info_summary mis ON mh.movie_id = mis.movie_id
WHERE 
    mh.level <= 3
ORDER BY 
    mh.production_year DESC, mh.title;
