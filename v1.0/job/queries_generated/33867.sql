WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m2.id AS movie_id,
        m2.title,
        m2.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id 
    JOIN 
        aka_title AS m2 ON ml.linked_movie_id = m2.id
),
actor_roles AS (
    SELECT 
        a.name,
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    JOIN 
        role_type AS rt ON ci.role_id = rt.id
    GROUP BY 
        a.name, ci.movie_id, rt.role
),
recent_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.production_year DESC) AS year_rank
    FROM 
        aka_title AS title
    WHERE 
        title.production_year >= 2000
)
SELECT 
    mh.movie_id,
    mh.title AS movie_title,
    mh.production_year,
    COALESCE(ar.role, 'Unknown') AS role,
    ar.role_count,
    CASE 
        WHEN mh.level > 2 THEN 'Deep Link'
        ELSE 'Surface Link'
    END AS link_depth,
    STRING_AGG(DISTINCT a.name, ', ') AS actors
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    actor_roles AS ar ON mh.movie_id = ar.movie_id
LEFT JOIN 
    recent_movies AS rm ON mh.movie_id = rm.movie_id
LEFT JOIN 
    cast_info AS ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name AS a ON ci.person_id = a.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, ar.role, ar.role_count, mh.level
HAVING 
    COUNT(ci.movie_id) > 1
ORDER BY 
    mh.production_year DESC, mh.title;
