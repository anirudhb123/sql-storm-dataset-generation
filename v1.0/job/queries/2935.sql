WITH RankedTitles AS (
    SELECT 
        at.id AS title_id, 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_by_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
KeywordCounts AS (
    SELECT 
        movie_id, 
        COUNT(mv.id) AS keyword_count
    FROM 
        movie_keyword mv
    GROUP BY 
        movie_id
),
FullCast AS (
    SELECT 
        cc.movie_id, 
        COUNT(DISTINCT cc.person_id) AS total_cast_members
    FROM 
        cast_info cc
    JOIN 
        aka_title at ON cc.movie_id = at.movie_id
    GROUP BY 
        cc.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(CASE 
                    WHEN cn.country_code IS NOT NULL THEN cn.name 
                    ELSE 'Unknown' 
                END, ', ') AS companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title, 
    rt.production_year, 
    kc.keyword_count, 
    fc.total_cast_members, 
    cd.companies
FROM 
    RankedTitles rt
LEFT JOIN 
    KeywordCounts kc ON rt.title_id = kc.movie_id
LEFT JOIN 
    FullCast fc ON rt.title_id = fc.movie_id
LEFT JOIN 
    CompanyDetails cd ON rt.title_id = cd.movie_id
WHERE 
    rt.rank_by_year <= 10 
    AND (kc.keyword_count IS NULL OR kc.keyword_count > 0)
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
