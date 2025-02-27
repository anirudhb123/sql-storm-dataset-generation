WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(m2.id, 0) AS related_movie_id
    FROM 
        aka_title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    LEFT JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(m2.id, 0) AS related_movie_id
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_link ml ON mh.related_movie_id = ml.movie_id
    LEFT JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE 
        m2.production_year >= 2000
),
cast_with_roles AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS cast_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        MAX(a.name) AS main_actor
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
movie_info_data AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
combined_data AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cwr.cast_count,
        cwr.roles,
        cwr.main_actor,
        mid.info_type_count,
        mid.info_details
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_with_roles cwr ON mh.movie_id = cwr.movie_id
    LEFT JOIN 
        movie_info_data mid ON mh.movie_id = mid.movie_id
)
SELECT 
    cd.movie_id,
    cd.title,
    cd.production_year,
    ISNULL(cd.cast_count, 0) AS total_cast,
    COALESCE(cd.roles, 'No roles') AS role_list,
    COALESCE(cd.main_actor, 'Unknown') AS top_actor,
    ISNULL(cd.info_type_count, 0) AS total_info_types,
    COALESCE(cd.info_details, 'No additional info') AS additional_info,
    CASE WHEN cd.cast_count IS NULL THEN 'No cast' ELSE 'Has cast' END AS cast_status
FROM 
    combined_data cd
WHERE 
    cd.production_year = (
        SELECT 
            MAX(production_year)
        FROM 
            combined_data
    )
ORDER BY 
    cd.title ASC;
