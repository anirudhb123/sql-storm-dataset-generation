WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m 
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1,
        CAST(mh.path || ' -> ' || m.title AS VARCHAR(255))
    FROM 
        aka_title m 
    JOIN 
        movie_hierarchy mh 
    ON 
        m.episode_of_id = mh.movie_id
),
cast_role AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        MAX(rt.role) AS primary_role
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
standard_info AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(k.keywords, 'No Keywords') AS keywords,
        COALESCE(cr.cast_count, 0) AS cast_count,
        COALESCE(cr.primary_role, 'Unknown') AS primary_role
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keywords k ON m.id = k.movie_id
    LEFT JOIN 
        cast_role cr ON m.id = cr.movie_id
)

SELECT 
    sh.movie_id,
    sh.title,
    sh.keywords,
    sh.cast_count,
    sh.primary_role,
    mh.level AS hierarchy_level,
    mh.path AS hierarchy_path
FROM 
    standard_info sh
JOIN 
    movie_hierarchy mh ON sh.movie_id = mh.movie_id
ORDER BY 
    mh.level, 
    sh.title;