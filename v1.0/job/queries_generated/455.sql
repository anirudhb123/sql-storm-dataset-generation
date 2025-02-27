WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(CASE WHEN c.country_code IS NULL THEN 'Unknown' ELSE c.country_code END, 'No Country') AS country
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
TitleKeywords AS (
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
    rm.movie_id,
    rm.title,
    rm.production_year,
    ci.company_name,
    ci.company_type,
    ci.country,
    tk.keywords,
    COUNT(DISTINCT ci.company_name) OVER (PARTITION BY rm.movie_id) AS total_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    TitleKeywords tk ON rm.movie_id = tk.movie_id
WHERE 
    (rm.production_year >= 2000 AND rm.production_year <= 2023)
    OR (rm.title LIKE '%Academy%' AND tk.keywords IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
