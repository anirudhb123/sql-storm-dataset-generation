WITH RECURSIVE movie_hierarchy AS (
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.episode_of_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        e.episode_of_id,
        mh.level + 1
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),


actor_role_count AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),


actor_avg_year AS (
    SELECT 
        ci.person_id,
        AVG(a.production_year) AS avg_production_year
    FROM 
        cast_info ci
    JOIN 
        aka_title a ON ci.movie_id = a.id
    GROUP BY 
        ci.person_id
),


movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COALESCE(arc.role_count, 0) AS total_roles,
        COALESCE(aavy.avg_production_year, 0) AS actor_avg_year
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        actor_role_count arc ON ci.person_id = arc.person_id
    LEFT JOIN 
        actor_avg_year aavy ON ci.person_id = aavy.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, arc.role_count, aavy.avg_production_year
)


SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.total_roles,
    md.actor_avg_year,
    CASE 
        WHEN md.total_roles = 0 THEN 'No roles'
        WHEN md.total_roles < 5 THEN 'Few roles'
        ELSE 'Many roles'
    END AS role_category
FROM 
    movie_details md
WHERE 
    md.total_cast > 0
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC;