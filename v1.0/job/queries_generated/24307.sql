WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY at.production_year) AS total_titles
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        AVG(CASE WHEN cu.name_pcode_nf IS NOT NULL THEN 1 ELSE 0 END) AS pct_companies_known
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        company_name cu ON mc.company_id = cu.id
    GROUP BY 
        mc.movie_id
),
CastInfo AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(CONCAT(a.name, ' as ', rt.role) ORDER BY ci.nr_order) AS full_cast,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    cs.company_count,
    cs.pct_companies_known,
    ci.full_cast,
    ci.cast_count,
    COALESCE((SELECT AVG(production_year) FROM RankedTitles WHERE production_year < rt.production_year), 'No earlier productions') AS prev_avg_year
FROM 
    RankedTitles rt
JOIN 
    CompanyStats cs ON rt.id = cs.movie_id
LEFT JOIN 
    CastInfo ci ON rt.id = ci.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
