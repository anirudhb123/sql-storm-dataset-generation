WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM t.production_year) ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.id, t.title, t.production_year
), title_info AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.keyword_count,
        m.id AS movie_id,
        string_agg(coalesce(pi.info, 'N/A'), '; ') AS person_info
    FROM 
        ranked_titles rt
    LEFT JOIN 
        complete_cast cc ON rt.title_id = cc.movie_id
    LEFT JOIN 
        aka_name an ON cc.subject_id = an.id
    LEFT JOIN 
        person_info pi ON an.person_id = pi.person_id
    LEFT JOIN 
        movie_info mi ON rt.title_id = mi.movie_id
    GROUP BY 
        rt.title_id, rt.title, rt.production_year, m.id
), final_results AS (
    SELECT 
        ti.title,
        ti.production_year,
        ti.keyword_count,
        COALESCE(SUM(mc.note IS NOT NULL)::int, 0) AS companies_count,
        ti.person_info
    FROM 
        title_info ti
    LEFT JOIN 
        movie_companies mc ON ti.movie_id = mc.movie_id
    GROUP BY 
        ti.title_id, ti.title, ti.production_year, ti.keyword_count, ti.person_info
)
SELECT 
    *,
    CASE 
        WHEN keyword_count > 5 THEN 'Highly Tagged'
        WHEN keyword_count BETWEEN 3 AND 5 THEN 'Moderately Tagged'
        ELSE 'Less Tagged'
    END AS tag_category
FROM 
    final_results
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, keyword_count DESC;
