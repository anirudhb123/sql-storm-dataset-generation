WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
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
), 
CastAndRoles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(ci.person_id) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
), 
DistinctKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cm.company_name,
    cm.company_type,
    car.role,
    car.total_cast,
    dk.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyMovies cm ON rt.title_id = cm.movie_id
LEFT JOIN 
    CastAndRoles car ON rt.title_id = car.movie_id
LEFT JOIN 
    DistinctKeywords dk ON rt.title_id = dk.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
