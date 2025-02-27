WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
ranked_cast AS (
    SELECT 
        c.id AS cast_id,
        CONCAT(a.name, ' as ', r.role) AS actor_role,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        role_type r ON r.id = c.role_id
),
keyword_count AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON m.id = mk.movie_id
    GROUP BY 
        m.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info ORDER BY it.info) AS info_aggregated
    FROM 
        movie_info mi
    JOIN 
        info_type it ON it.id = mi.info_type_id
    GROUP BY 
        mi.movie_id
),
combined_result AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COALESCE(rc.actor_role, 'No Cast') AS lead_actor,
        COALESCE(kc.keyword_count, 0) AS total_keywords,
        COALESCE(mis.info_aggregated, 'No Info') AS additional_info,
        mh.level
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        ranked_cast rc ON rc.movie_id = mh.movie_id AND rc.role_rank = 1
    LEFT JOIN 
        keyword_count kc ON kc.movie_id = mh.movie_id
    LEFT JOIN 
        movie_info_summary mis ON mis.movie_id = mh.movie_id
)
SELECT 
    movie_id,
    title,
    lead_actor,
    total_keywords,
    additional_info,
    level
FROM 
    combined_result
WHERE 
    total_keywords > 0
ORDER BY 
    total_keywords DESC, 
    title;
