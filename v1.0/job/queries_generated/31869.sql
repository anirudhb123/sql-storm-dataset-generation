WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(t.production_year, 0) AS production_year,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(t.production_year, 0),
        mh.level + 1
    FROM 
        aka_title t
    INNER JOIN 
        movie_hierarchy mh ON t.episode_of_id = mh.movie_id
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_id) AS number_of_cast
    FROM 
        cast_info ci
    INNER JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
highlights AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        MAX(cr.number_of_cast) AS max_cast_count,
        MIN(cr.number_of_cast) AS min_cast_count
    FROM 
        movie_hierarchy m
    LEFT JOIN 
        cast_roles cr ON m.movie_id = cr.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.movie_id, m.title, m.production_year
    HAVING 
        MAX(cr.number_of_cast) > 5
)
SELECT 
    hl.title,
    hl.production_year,
    hl.max_cast_count,
    hl.min_cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM 
    highlights hl
LEFT JOIN 
    cast_info ci ON hl.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    hl.movie_id, hl.title, hl.production_year, hl.max_cast_count, hl.min_cast_count
ORDER BY 
    hl.production_year DESC, hl.title;
