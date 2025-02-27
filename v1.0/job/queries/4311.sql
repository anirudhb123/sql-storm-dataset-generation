WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
CompanyTitles AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
        JOIN company_name c ON mc.company_id = c.id
        JOIN company_type ct ON mc.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CastInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        MAX(r.role) AS top_role
    FROM 
        cast_info ci
        JOIN role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ct.company_name,
    ct.company_type,
    mk.keywords,
    ci.cast_count,
    ci.top_role
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyTitles ct ON ct.movie_id = rt.title_id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rt.title_id
JOIN 
    CastInfo ci ON ci.movie_id = rt.title_id
WHERE 
    (rt.rank = 1 OR ci.cast_count IS NULL)
    AND (ci.top_role IS NOT NULL OR ct.company_type LIKE '%Film%')
ORDER BY 
    rt.production_year DESC, rt.title;
