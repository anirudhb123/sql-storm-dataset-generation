WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS level
    FROM 
        aka_title m 
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1 AS level
    FROM 
        aka_title m
    JOIN
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),

CastRoles AS (
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

MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(CASE WHEN it.info = 'budget' THEN mi.info END, ', ') AS budgets,
        STRING_AGG(CASE WHEN it.info = 'box office' THEN mi.info END, ', ') AS box_offices
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
    COALESCE(cr.role, 'Unknown Role') AS role,
    mh.level,
    COALESCE(mi.budgets, 'N/A') AS budgets,
    COALESCE(mi.box_offices, 'N/A') AS box_offices,
    COUNT(DISTINCT ka.person_id) AS actor_count,
    COUNT(DISTINCT kc.id) AS keyword_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastRoles cr ON mh.movie_id = cr.movie_id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ka ON cc.subject_id = ka.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.level <= 1 AND 
    (cr.role IS NULL OR cr.role NOT LIKE '%Extra%') -- ignore extras
GROUP BY 
    mh.movie_id, mh.title, cr.role, mh.level, mi.budgets, mi.box_offices
ORDER BY 
    mh.level, mh.title
OFFSET 10 LIMIT 5; -- pagination example
