
WITH movie_info_aggregated AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ' | ') AS all_info,
        COUNT(mi.info_type_id) AS info_count
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
title_with_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ka.name AS actor_name,
        ka.id AS actor_id,
        mc.all_info,
        mc.info_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name ka ON cc.subject_id = ka.person_id
    LEFT JOIN 
        movie_info_aggregated mc ON mc.movie_id = t.id
    WHERE 
        t.production_year > 2000
),
keyword_counts AS (
    SELECT 
        mw.movie_id,
        COUNT(mw.keyword_id) AS keyword_count
    FROM 
        movie_keyword mw
    GROUP BY 
        mw.movie_id
),
final_report AS (
    SELECT 
        ti.title_id,
        ti.title,
        ti.production_year,
        ti.actor_name,
        ti.all_info,
        kc.keyword_count,
        ti.info_count
    FROM 
        title_with_info ti
    LEFT JOIN 
        keyword_counts kc ON ti.title_id = kc.movie_id
    ORDER BY 
        ti.production_year DESC,
        ti.title
)

SELECT 
    fr.title_id,
    fr.title,
    fr.production_year,
    fr.actor_name,
    fr.all_info,
    COALESCE(fr.keyword_count, 0) AS keyword_count
FROM 
    final_report fr
WHERE 
    fr.info_count > 1
LIMIT 100;
