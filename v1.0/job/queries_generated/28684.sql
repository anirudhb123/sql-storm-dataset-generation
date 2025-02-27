WITH movie_role_counts AS (
    SELECT 
        ci.movie_id,
        rt.role AS role,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.person_role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),

movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),

movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, ', ') AS info_types, 
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    t.title,
    t.production_year,
    COALESCE(mrc.role_count, 0) AS total_roles,
    COALESCE(mkc.keyword_count, 0) AS total_keywords,
    COALESCE(mis.info_types, 'No additional info') AS additional_info_types,
    COALESCE(mis.info_details, 'No info available') AS additional_info_details
FROM 
    title t
LEFT JOIN 
    movie_role_counts mrc ON t.id = mrc.movie_id
LEFT JOIN 
    movie_keyword_counts mkc ON t.id = mkc.movie_id
LEFT JOIN 
    movie_info_summary mis ON t.id = mis.movie_id
ORDER BY 
    t.production_year DESC, 
    t.title;
