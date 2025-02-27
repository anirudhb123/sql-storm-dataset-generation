WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
),
CompanyDetails AS (
    SELECT 
        m.movie_id, 
        c.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.actor_name, 
    rt.title, 
    rt.production_year, 
    COALESCE(cd.company_name, 'No Company') AS company_name,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyDetails cd ON rt.title = cd.movie_id 
LEFT JOIN 
    KeywordCounts kc ON rt.title = kc.movie_id
WHERE 
    rt.rank = 1
ORDER BY 
    rt.production_year DESC, 
    rt.actor_name ASC;
