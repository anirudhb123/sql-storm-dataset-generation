
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
RecentMovies AS (
    SELECT 
        DISTINCT movie_id
    FROM 
        cast_info
    WHERE 
        person_role_id = (SELECT id FROM role_type WHERE role = 'Actor')
),
CompanyDetails AS (
    SELECT 
        m.id AS movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    WHERE 
        c.country_code = 'USA'
),
TitleKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    COALESCE(cd.company_name, 'Independent') AS production_company,
    tk.keywords,
    COUNT(DISTINCT ci.person_id) AS actor_count
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    RecentMovies rm ON rt.title_id = rm.movie_id
LEFT JOIN 
    cast_info ci ON rt.title_id = ci.movie_id AND ci.person_role_id = (SELECT id FROM role_type WHERE role = 'Actor')
LEFT JOIN 
    TitleKeywords tk ON rt.title_id = tk.movie_id
WHERE 
    rt.rn <= 5
GROUP BY 
    rt.title_id, rt.title, rt.production_year, cd.company_name, tk.keywords
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    rt.production_year DESC, rt.title;
