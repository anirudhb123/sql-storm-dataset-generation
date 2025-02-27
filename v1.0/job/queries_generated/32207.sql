WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_stats AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN r.role LIKE 'Lead%' THEN 1 ELSE 0 END) AS lead_roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
movie_info_summary AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        STRING_AGG(mi.info, ', ') AS info_list
    FROM 
        movie_info mi
    JOIN 
        aka_title m ON mi.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.lead_roles, 0) AS lead_roles,
    COALESCE(mis.info_count, 0) AS info_count,
    COALESCE(mis.info_list, 'No Info') AS info_list,
    CASE 
        WHEN mh.production_year IS NOT NULL THEN mh.level * 10
        ELSE NULL
    END AS hierarchy_level_calculation
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_stats cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movie_info_summary mis ON mh.movie_id = mis.movie_id
ORDER BY 
    mh.production_year DESC, 
    mh.title;
