WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id, 
        a.name AS aka_name, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rnk
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
),
CompanyMovies AS (
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
    WHERE 
        c.country_code IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id, 
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    rt.aka_name, 
    rt.title, 
    rt.production_year, 
    cm.company_name, 
    cm.company_type, 
    mwk.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyMovies cm ON rt.title = cm.movie_id
JOIN 
    MoviesWithKeywords mwk ON rt.title = mwk.movie_id
WHERE 
    rt.rnk = 1 
    AND rt.production_year >= 2000 
    AND (cm.company_name IS NOT NULL OR mwk.keywords IS NOT NULL)
ORDER BY 
    rt.production_year DESC, 
    rt.aka_name;
