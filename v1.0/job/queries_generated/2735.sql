WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title, 
        a.production_year, 
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.id DESC) AS year_rank,
        COALESCE(k.keyword, 'No Keyword') AS keyword_used
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year > 2000
),
CompanyMovies AS (
    SELECT 
        m.title, 
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.name) AS company_order
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.keyword_used,
    COUNT(DISTINCT cm.company_name) AS num_companies,
    MAX(cm.company_type) AS top_company_type,
    SUM(CASE WHEN cm.company_order = 1 THEN 1 ELSE 0 END) AS has_top_ranked_company
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovies cm ON rm.movie_title = cm.title
GROUP BY 
    rm.movie_title, rm.production_year, rm.keyword_used
HAVING 
    COUNT(DISTINCT cm.company_name) > 1
ORDER BY 
    rm.production_year DESC, num_companies DESC;
