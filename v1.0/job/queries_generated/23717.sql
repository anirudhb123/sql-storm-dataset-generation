WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.depth < 3
),

cast_roles AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_role_id) AS role_count,
        MAX(rt.role) AS main_role
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),

company_info AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IN ('USA', 'CAN')
    GROUP BY 
        mc.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cr.role_count, 0) AS total_roles,
    cr.main_role AS predominant_role,
    COALESCE(ci.company_count, 0) AS unique_companies,
    ci.companies AS company_names,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS year_rank,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Unknown Year'
        ELSE mh.production_year::text
    END AS production_year_display,
    'Depth ' || mh.depth AS movie_depth
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_roles cr ON mh.movie_id = cr.movie_id
LEFT JOIN 
    company_info ci ON mh.movie_id = ci.movie_id
WHERE 
    mh.production_year >= 2000
    AND (ci.company_count IS NULL OR ci.company_count > 1)
ORDER BY 
    mh.production_year DESC, mh.title;
