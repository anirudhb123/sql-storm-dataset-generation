
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.movie_id AS parent_id
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),
cast_aggregates AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT CONCAT(COALESCE(aka.name, 'Unknown'), '(', COALESCE(rt.role, 'No Role'), ')'), ', ') AS cast_list
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name aka ON ci.person_id = aka.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
company_aggregates AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ca.total_cast, 0) AS total_cast,
    COALESCE(ca.cast_list, '') AS cast_list,
    COALESCE(co.total_companies, 0) AS total_companies,
    COALESCE(co.company_names, '') AS company_names,
    CASE 
        WHEN COALESCE(co.total_companies, 0) > 0 THEN 'Produced'
        ELSE 'Independent'
    END AS production_type
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_aggregates ca ON mh.movie_id = ca.movie_id
LEFT JOIN 
    company_aggregates co ON mh.movie_id = co.movie_id
WHERE 
    mh.production_year >= 2000
    AND (COALESCE(co.total_companies, 0) >= 1)
ORDER BY 
    mh.production_year DESC,
    mh.title ASC
LIMIT 50;
