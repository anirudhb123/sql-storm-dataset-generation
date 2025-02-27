WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
),
PopularTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        COUNT(c.movie_id) AS cast_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        cast_info c ON rt.title_id = c.movie_id
    GROUP BY 
        rt.title_id, rt.title, rt.production_year
    HAVING 
        COUNT(c.movie_id) > 1
),
TopCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
    HAVING 
        COUNT(mc.company_id) >= 3
),
ExtendedInfo AS (
    SELECT 
        pt.title,
        pt.production_year,
        tc.company_id,
        tn.name AS company_name,
        tc.company_type_id,
        ct.kind AS company_type
    FROM 
        PopularTitles pt
    JOIN 
        TopCompanies tc ON pt.title_id = tc.movie_id
    JOIN 
        company_name tn ON tc.company_id = tn.id
    JOIN 
        company_type ct ON tc.company_type_id = ct.id
),
FinalBenchmark AS (
    SELECT 
        ei.title,
        ei.production_year,
        ei.company_name,
        ei.company_type,
        ROW_NUMBER() OVER (ORDER BY ei.production_year DESC, ei.title) AS ranking
    FROM 
        ExtendedInfo ei
)

SELECT 
    title,
    production_year,
    company_name,
    company_type,
    ranking
FROM 
    FinalBenchmark
ORDER BY 
    production_year DESC, ranking;
