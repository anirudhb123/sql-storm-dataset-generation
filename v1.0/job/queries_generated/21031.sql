WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
),
company_movies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),
character_info AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_notes_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cm.company_name,
    cm.company_type,
    ci.total_cast,
    ci.cast_notes_count,
    CASE 
        WHEN ci.total_cast > 5 THEN 'Large Cast'
        WHEN ci.total_cast BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    CONCAT(rt.title, ' (', rt.production_year, ')') AS detailed_title,
    COALESCE(NULLIF(UPPER(rt.title), LOWER(rt.title)), 'Case Insensitive') AS title_case_check,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    ranked_titles rt
LEFT JOIN 
    company_movies cm ON rt.title_id = cm.movie_id
LEFT JOIN 
    character_info ci ON rt.title_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    rt.production_year >= 2000
    AND (cm.company_name IS NULL OR cm.company_type = 'Distributor')
GROUP BY 
    rt.title, rt.production_year, cm.company_name, cm.company_type, ci.total_cast, ci.cast_notes_count
HAVING 
    COUNT(DISTINCT k.keyword) > 0
ORDER BY 
    rt.production_year DESC, rt.title;
