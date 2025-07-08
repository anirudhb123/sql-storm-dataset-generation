
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(CASE WHEN k.keyword IS NOT NULL THEN 1 END) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
title_details AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.title_rank,
        COALESCE(ci.note, 'No role specified') AS role_note,
        ci.nr_order,
        rt.keyword_count,
        (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = rt.title_id) AS company_count
    FROM 
        ranked_titles rt
    LEFT JOIN 
        complete_cast cc ON rt.title_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        rt.title_rank < 5 AND rt.production_year IS NOT NULL
),
movie_summary AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count,
        LISTAGG(DISTINCT n.name, ', ') WITHIN GROUP (ORDER BY n.name) AS cast_names,
        SUM(CASE WHEN mc.company_type_id IS NOT NULL THEN 1 ELSE 0 END) AS production_companies
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        aka_name n ON ci.person_id = n.person_id
    WHERE 
        ci.nr_order IS NOT NULL
    GROUP BY 
        t.id, t.title
)
SELECT 
    td.title,
    td.production_year,
    td.role_note,
    td.keyword_count,
    ms.distinct_cast_count,
    ms.production_companies
FROM 
    title_details td
JOIN 
    movie_summary ms ON td.title_id = ms.title_id
WHERE 
    td.keyword_count > 2
ORDER BY 
    td.production_year DESC, 
    ms.distinct_cast_count DESC
LIMIT 10;
