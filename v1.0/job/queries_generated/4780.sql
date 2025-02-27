WITH movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        mt.id
),
company_summary AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS total_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        it.info AS additional_info
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.actor_names,
    cs.company_name,
    cs.company_type,
    COALESCE(ti.additional_info, 'No additional info') AS additional_info
FROM 
    movie_details md
LEFT JOIN 
    company_summary cs ON md.movie_id = cs.movie_id
LEFT JOIN 
    title_info ti ON md.movie_id = ti.title_id
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC,
    md.cast_count DESC
LIMIT 100
UNION ALL
SELECT 
    NULL AS movie_id,
    'Total Count' AS title,
    NULL AS production_year,
    SUM(cast_count) AS cast_count,
    NULL AS actor_names,
    NULL AS company_name,
    NULL AS company_type,
    NULL AS additional_info
FROM 
    movie_details;
