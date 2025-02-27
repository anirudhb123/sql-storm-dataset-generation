WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rn <= 5
),
MovieInfoWithCounts AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT mi.info) AS info_count
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(ct.id) AS type_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
CombinedData AS (
    SELECT 
        at.title_id,
        at.title,
        at.production_year,
        coalesce(mic.info_count, 0) AS movie_info_count,
        coalesce(ci.type_count, 0) AS company_type_count,
        ci.company_name
    FROM 
        FilteredTitles at
    LEFT JOIN 
        MovieInfoWithCounts mic ON at.title_id = mic.movie_id
    LEFT JOIN 
        CompanyInfo ci ON at.title_id = ci.movie_id
)
SELECT 
    cd.title, 
    cd.production_year,
    cd.movie_info_count,
    MAX(cd.company_type_count) AS max_company_type_count,
    STRING_AGG(DISTINCT cd.company_name, ', ') AS associated_companies
FROM 
    CombinedData cd
GROUP BY 
    cd.title, cd.production_year, cd.movie_info_count
ORDER BY 
    cd.production_year DESC, cd.title;
