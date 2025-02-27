WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS level 
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title AS movie_title,
        e.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON mh.movie_id = e.episode_of_id
),

keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS total_keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),

role_distribution AS (
    SELECT 
        ci.movie_id,
        rt.role AS role_type,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    INNER JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),

movie_info_extended AS (
    SELECT 
        ti.title AS movie_title,
        ti.production_year,
        COALESCE(kc.total_keywords, 0) AS total_keywords,
        COALESCE(ri.role_count, 0) AS total_roles
    FROM 
        aka_title ti
    LEFT JOIN 
        keyword_count kc ON ti.id = kc.movie_id
    LEFT JOIN 
        role_distribution ri ON ti.id = ri.movie_id
)

SELECT 
    m.movie_title,
    m.production_year,
    mh.level,
    m.total_keywords,
    m.total_roles
FROM 
    movie_info_extended m
JOIN 
    movie_hierarchy mh ON m.movie_title = mh.movie_title AND m.production_year = mh.production_year
ORDER BY 
    mh.level, m.production_year DESC
FETCH FIRST 10 ROWS ONLY;