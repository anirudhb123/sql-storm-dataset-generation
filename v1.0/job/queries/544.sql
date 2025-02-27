WITH ranked_titles AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
company_info AS (
    SELECT 
        c.id AS company_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        company_name c
    JOIN 
        company_type ct ON c.id = ct.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    at.title,
    at.production_year,
    rt.year_rank,
    ci.company_name,
    ci.company_type,
    mk.keywords,
    COUNT(DISTINCT ci.company_id) AS total_companies
FROM 
    aka_title at
LEFT JOIN 
    ranked_titles rt ON at.id = rt.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = at.id
LEFT JOIN 
    company_info ci ON mc.company_id = ci.company_id
LEFT JOIN 
    movie_keywords mk ON mk.movie_id = at.id
WHERE 
    (at.production_year >= 2000 OR at.kind_id IS NULL)
    AND (ci.company_type IS NOT NULL OR at.title LIKE '%Award%')
GROUP BY 
    at.title, at.production_year, rt.year_rank, ci.company_name, ci.company_type, mk.keywords
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    at.production_year DESC, rt.year_rank;
