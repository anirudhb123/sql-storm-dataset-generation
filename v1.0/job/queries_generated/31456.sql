WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        0 AS level,
        m.title,
        m.production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT
        e.id AS movie_id,
        level + 1,
        e.title,
        e.production_year,
        h.movie_id AS parent_movie_id
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy h ON e.episode_of_id = h.movie_id
),
roles_with_counts AS (
    SELECT
        ci.movie_id,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM
        cast_info ci
    INNER JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
top_roles AS (
    SELECT
        movie_id,
        role,
        role_count,
        ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY role_count DESC) AS rnk
    FROM 
        roles_with_counts
),
company_movie_count AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT
    h.movie_id,
    h.title,
    h.production_year,
    ARRAY_AGG(DISTINCT r.role) AS all_roles,
    COALESCE(max(r.role_count), 0) AS max_role_count,
    COALESCE(cm.company_count, 0) AS company_count,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = h.movie_id)) AS distinct_actors_count
FROM 
    movie_hierarchy h
LEFT JOIN 
    top_roles r ON h.movie_id = r.movie_id AND r.rnk <= 3
LEFT JOIN 
    company_movie_count cm ON h.movie_id = cm.movie_id
GROUP BY 
    h.movie_id, h.title, h.production_year
ORDER BY 
    h.production_year DESC, h.movie_id;
