WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title AS movie_title,
    rt.production_year,
    COALESCE(ki.keyword_count, 0) AS total_keywords,
    ci.company_name,
    ci.company_type
FROM 
    RankedTitles rt
LEFT JOIN 
    KeywordCount ki ON rt.title_id = ki.movie_id
LEFT JOIN 
    CompanyInfo ci ON rt.title_id = ci.movie_id
WHERE 
    rt.rank = 1
ORDER BY 
    rt.production_year DESC, rt.title;
