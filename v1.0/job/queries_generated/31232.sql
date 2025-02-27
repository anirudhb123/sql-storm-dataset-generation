WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.linked_movie_id
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS cast_count,
        STRING_AGG(a.name, ', ') AS actors,
        AVG(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS role_present_ratio
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        role_type r ON r.id = ci.role_id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cwr.cast_count, 0) AS total_cast,
        COALESCE(cwr.actors, 'No Cast') AS cast_list,
        COALESCE(cwr.role_present_ratio, 0) AS role_ratio,
        CASE 
            WHEN mh.depth > 1 THEN 'Linked'
            ELSE 'Standalone'
        END AS movie_type
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_with_roles cwr ON mh.movie_id = cwr.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_list,
    md.role_ratio,
    md.movie_type,
    COUNT(DISTINCT kc.keyword) AS keyword_count
FROM 
    movie_details md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON kc.id = mk.keyword_id
WHERE 
    md.role_ratio < 0.75
GROUP BY 
    md.title, md.production_year, md.total_cast, md.cast_list, md.role_ratio, md.movie_type
ORDER BY 
    md.production_year DESC, keyword_count DESC
LIMIT 50;
