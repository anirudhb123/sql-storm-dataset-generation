WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.nr_order) AS rank_order
    FROM 
        aka_title a
    JOIN 
        cast_info b ON a.id = b.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyInfo AS (
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
)
SELECT 
    rt.title,
    rt.production_year,
    rt.rank_order,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(ci.company_name, 'No company') AS company_name,
    ci.company_type,
    CASE 
        WHEN rt.production_year < 2000 THEN 'Classic'
        WHEN rt.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieKeywords mk ON rt.title = mk.movie_id
LEFT JOIN 
    CompanyInfo ci ON rt.title = ci.movie_id
WHERE 
    rt.rank_order <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.rank_order;
