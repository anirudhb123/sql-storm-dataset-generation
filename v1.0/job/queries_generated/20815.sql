WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 1900) AS production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mk.linked_movie_id AS movie_id,
        t.title,
        COALESCE(t.production_year, 1900),
        mh.level + 1
    FROM 
        movie_link mk
    JOIN 
        title t ON mk.linked_movie_id = t.id
    JOIN 
        movie_hierarchy mh ON mk.movie_id = mh.movie_id
    WHERE 
        mh.level < 10
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        p.name AS actor_name,
        cr.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type cr ON ci.role_id = cr.id
),
advanced_filter AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT cwr.actor_name) AS actor_count,
        STRING_AGG(DISTINCT cwr.role || ' (' || cwr.actor_name || ')', ', ') AS roles
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_with_roles cwr ON mh.movie_id = cwr.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(DISTINCT cwr.role) > 2 AND 
        MAX(mh.production_year) > 2000
)
SELECT 
    af.movie_id,
    af.title,
    af.production_year,
    af.actor_count,
    af.roles,
    CASE 
        WHEN af.actor_count IS NULL THEN 'No Actors'
        ELSE 'Has Actors'
    END AS actor_status,
    CASE 
        WHEN af.actor_count <= 5 THEN 'Low'
        WHEN af.actor_count BETWEEN 6 AND 20 THEN 'Medium'
        ELSE 'High'
    END AS actor_density_category
FROM 
    advanced_filter af
WHERE 
    af.production_year BETWEEN 1990 AND 2023
ORDER BY 
    af.actor_density_category DESC,
    af.production_year DESC NULLS LAST;
