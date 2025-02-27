WITH RecursiveTitle AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 
PopularKeywords AS (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
    HAVING 
        COUNT(mk.keyword_id) > 5
), 
MovieRoleCount AS (
    SELECT 
        ci.movie_id, 
        COUNT(ci.role_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
), 
TitleWithCompanies AS (
    SELECT 
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    rt.title,
    rt.production_year,
    rc.role_count,
    kw.keyword_count,
    CASE 
        WHEN rc.role_count IS NULL THEN 'No roles'
        ELSE CAST(rc.role_count AS VARCHAR)
    END AS role_summary,
    COALESCE(array_to_string(tc.company_names, ', '), 'No companies') AS companies
FROM 
    RecursiveTitle rt
LEFT JOIN 
    MovieRoleCount rc ON rc.movie_id = rt.title_id
LEFT JOIN 
    PopularKeywords kw ON kw.movie_id = rt.title_id
LEFT JOIN 
    TitleWithCompanies tc ON tc.title = rt.title AND tc.production_year = rt.production_year
WHERE 
    rt.rank_by_year <= 10
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
