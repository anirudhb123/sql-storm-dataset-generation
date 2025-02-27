WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 
cast_with_role AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role AS person_role,
        COALESCE(n.gender, 'U') AS gender
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        aka_name n ON c.person_id = n.person_id
), 
movie_keywords AS (
    SELECT 
        mv.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mv
    JOIN 
        keyword k ON mv.keyword_id = k.id
    GROUP BY 
        mv.movie_id
), 
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cwr.person_role,
    cwr.gender,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(cd.company_names, 'No Companies') AS companies,
    CASE 
        WHEN rt.year_rank = 1 THEN 'First Released'
        WHEN rt.year_rank = (SELECT MAX(year_rank) FROM ranked_titles WHERE production_year = rt.production_year) THEN 'Last Released in Year'
        ELSE 'Released'
    END AS release_status
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_with_role cwr ON rt.title_id = cwr.movie_id
LEFT JOIN 
    movie_keywords mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    company_details cd ON rt.title_id = cd.movie_id
WHERE 
    rt.production_year > 1990
    AND (cwr.gender IS NULL OR cwr.gender = 'F' OR cwr.gender = 'M')
ORDER BY 
    rt.production_year DESC, 
    rt.title;
