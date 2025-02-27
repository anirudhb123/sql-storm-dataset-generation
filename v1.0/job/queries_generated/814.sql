WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        c.name AS company_name, 
        ct.kind AS company_type
    FROM 
        company_name c
    LEFT JOIN 
        company_type ct ON c.id = ct.id
),
MovieInformation AS (
    SELECT 
        mi.movie_id, 
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
CompleteCastInfo AS (
    SELECT 
        cc.movie_id, 
        COUNT(cc.subject_id) AS total_cast
    FROM 
        complete_cast cc
    GROUP BY 
        cc.movie_id
)
SELECT 
    rt.title, 
    rt.production_year, 
    c.company_name, 
    ci.total_cast, 
    mi.info_details
FROM 
    RankedTitles rt
LEFT JOIN 
    movie_companies mc ON rt.production_year = mc.movie_id 
LEFT JOIN 
    CompanyDetails c ON mc.company_id = c.company_name
LEFT JOIN 
    CompleteCastInfo ci ON rt.production_year = ci.movie_id 
LEFT JOIN 
    MovieInformation mi ON rt.production_year = mi.movie_id 
WHERE 
    rt.title_rank <= 10
ORDER BY 
    rt.production_year DESC, 
    rt.title;
