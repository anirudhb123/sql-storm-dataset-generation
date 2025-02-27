WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        aka_name a ON t.id = a.id
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.role_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        MAX(ci.kind) AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ci ON mc.company_type_id = ci.id
    GROUP BY 
        mc.movie_id
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)

SELECT
    rm.title,
    rm.production_year,
    COALESCE(cr.role_count, 0) AS total_roles,
    COALESCE(ci.company_count, 0) AS total_companies,
    COALESCE(mk.keyword_count, 0) AS total_keywords,
    CASE 
        WHEN rm.rank IS NULL THEN 'Not Ranked'
        WHEN rm.rank <= 5 THEN 'Top 5'
        ELSE 'Below Top 5'
    END AS rank_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastRoles cr ON rm.title_id = cr.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.title_id = ci.movie_id
LEFT JOIN 
    MovieKeywordCounts mk ON rm.title_id = mk.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2023 
    AND (cr.role IS NULL OR cr.role LIKE '%Director%' OR cr.role IS NOT NULL)
ORDER BY 
    rm.production_year DESC,
    total_roles DESC,
    total_companies DESC;

-- Additional logic to capture NULL handling and obscure semantics
SELECT COUNT(*) 
FROM 
    (SELECT DISTINCT title_id 
     FROM RankedMovies 
     WHERE title IS NOT NULL) AS non_null_titles;

