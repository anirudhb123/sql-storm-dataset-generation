WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.nr_order DESC) AS title_rank
    FROM 
        aka_title a 
    INNER JOIN 
        cast_info b ON a.id = b.movie_id 
    WHERE 
        a.production_year IS NOT NULL
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id 
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id 
    WHERE 
        c.country_code IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)

SELECT 
    rt.title,
    rt.production_year,
    fc.company_name,
    fc.company_type,
    COALESCE(mw.keywords, 'No Keywords') AS keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    FilteredCompanies fc ON rt.title_rank = fc.company_rank
LEFT JOIN 
    MoviesWithKeywords mw ON rt.title = mw.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
