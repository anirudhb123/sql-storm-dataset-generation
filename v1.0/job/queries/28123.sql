WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
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
MostActiveCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
    HAVING 
        COUNT(DISTINCT mc.company_id) > 3
)
SELECT 
    rt.title,
    rt.production_year,
    rt.cast_count,
    pk.keyword_count,
    cac.company_count
FROM 
    RankedTitles rt
LEFT JOIN 
    PopularKeywords pk ON rt.title_id = pk.movie_id
LEFT JOIN 
    MostActiveCompanies cac ON rt.title_id = cac.movie_id
WHERE 
    rt.cast_count > 5
ORDER BY 
    rt.production_year DESC, 
    rt.cast_count DESC;
