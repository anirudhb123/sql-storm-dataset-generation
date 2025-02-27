WITH movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        m.production_year,
        m.kind_id,
        p.gender,
        c.name AS company_name,
        STRING_AGG(DISTINCT p_info.info, '; ') AS person_info
    FROM 
        title t
    JOIN 
        aka_title m ON t.id = m.movie_id
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        name p ON ci.person_id = p.id
    LEFT JOIN 
        person_info p_info ON p.id = p_info.person_id
    GROUP BY 
        t.id, t.title, m.production_year, m.kind_id, p.gender, c.name
),
final_benchmark AS (
    SELECT 
        ti.title_id,
        ti.title,
        ti.production_year,
        ti.kind_id,
        ti.gender,
        ti.company_name,
        ti.person_info,
        mk.keywords
    FROM 
        title_info ti
    LEFT JOIN 
        movie_keywords mk ON ti.title_id = mk.movie_id
)
SELECT 
    fb.title,
    fb.production_year,
    fb.kind_id,
    fb.gender,
    fb.company_name,
    fb.person_info,
    fb.keywords,
    COUNT(CASE WHEN fb.keywords IS NOT NULL THEN 1 END) AS keyword_count
FROM 
    final_benchmark fb
WHERE 
    fb.production_year >= 2000
GROUP BY 
    fb.title, fb.production_year, fb.kind_id, fb.gender, fb.company_name, fb.person_info, fb.keywords
ORDER BY 
    fb.production_year DESC, fb.title;
