WITH RankedTitles AS (
    SELECT 
        a.person_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL 
        AND a.name IS NOT NULL
),
CompanyTitleInfo AS (
    SELECT 
        mc.movie_id,
        mc.company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        mi.info AS movie_info
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%Box Office%')
),
MovieKeywordInfo AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
YearlyProduction AS (
    SELECT 
        t.production_year,
        COUNT(t.id) AS title_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.production_year
)
SELECT 
    rt.person_id,
    rt.title,
    rt.production_year,
    cti.company_name,
    cti.company_type,
    mki.keywords,
    yp.title_count,
    CASE 
        WHEN rt.title_rank = 1 THEN 'Latest Production'
        ELSE 'Earlier Production'
    END AS production_status
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyTitleInfo cti ON rt.production_year = cti.movie_id
LEFT JOIN 
    MovieKeywordInfo mki ON rt.production_year = mki.movie_id
LEFT JOIN 
    YearlyProduction yp ON rt.production_year = yp.production_year
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.person_id, rt.production_year DESC;