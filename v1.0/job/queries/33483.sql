
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level,
        m.production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title AS m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        h.level + 1 AS level,
        e.production_year,
        e.episode_of_id AS parent_movie_id
    FROM 
        aka_title AS e
    INNER JOIN 
        movie_hierarchy AS h ON h.movie_id = e.episode_of_id
),

movie_info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(COALESCE(mi.info, 'N/A'), '; ') AS info_details
    FROM 
        movie_info AS mi
    GROUP BY 
        mi.movie_id
),

cast_roles AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS role_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info AS c
    INNER JOIN 
        role_type AS r ON c.role_id = r.id
    WHERE 
        c.note IS NULL
    GROUP BY 
        c.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mr.role_count, 0) AS total_roles,
    COALESCE(mr.roles, 'No roles assigned') AS role_details,
    COALESCE(mid.info_details, 'No additional info') AS additional_info,
    CASE 
        WHEN mh.level = 1 THEN 'Original Movie'
        ELSE 'Episode Level ' || CAST(mh.level AS VARCHAR)
    END AS movie_type
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    cast_roles AS mr ON mh.movie_id = mr.movie_id
LEFT JOIN 
    movie_info_details AS mid ON mh.movie_id = mid.movie_id
WHERE 
    mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC, mh.title;
