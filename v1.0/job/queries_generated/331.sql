WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a 
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name, 
        ct.kind AS company_type, 
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FilteredMovies AS (
    SELECT 
        rt.actor_name,
        rt.movie_title,
        rt.production_year,
        cd.company_name,
        cd.company_type
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CompanyDetails cd ON rt.title_rank = 1 AND rt.production_year >= 2000
    WHERE 
        rt.production_year IS NOT NULL
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    COALESCE(company_name, 'Independent') AS production_company,
    COALESCE(company_type, 'N/A') AS type
FROM 
    FilteredMovies
WHERE 
    actor_name LIKE 'A%' AND 
    production_year IN (SELECT DISTINCT production_year FROM RankedTitles WHERE title_rank <= 5)
ORDER BY 
    production_year DESC, actor_name;
