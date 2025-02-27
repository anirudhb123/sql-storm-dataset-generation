WITH RankedTitles AS (
    SELECT 
        title.id AS title_id, 
        title.title, 
        title.production_year, 
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
CompanyMovies AS (
    SELECT 
        movie_companies.movie_id, 
        company_name.name AS company_name, 
        company_type.kind AS company_type
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        company_type ON movie_companies.company_type_id = company_type.id
),
CastRoles AS (
    SELECT 
        cast_info.movie_id, 
        COUNT(DISTINCT cast_info.role_id) AS role_count
    FROM 
        cast_info
    GROUP BY 
        cast_info.movie_id
),
KeywordCount AS (
    SELECT 
        movie_keyword.movie_id, 
        COUNT(keyword.id) AS keyword_count
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_keyword.movie_id
)
SELECT 
    r.title, 
    r.production_year, 
    c.company_name, 
    c.company_type,
    COALESCE(cr.role_count, 0) AS role_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM 
    RankedTitles r
LEFT JOIN 
    CompanyMovies c ON r.title_id = c.movie_id
LEFT JOIN 
    CastRoles cr ON r.title_id = cr.movie_id
LEFT JOIN 
    KeywordCount kc ON r.title_id = kc.movie_id
WHERE 
    r.rank <= 5
ORDER BY 
    r.production_year DESC, 
    r.title;
