
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        r.role, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year, r.role ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        role_type r ON t.kind_id = r.id
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        mc.movie_id, 
        c.name AS company_name, 
        k.keyword AS keyword 
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    rt.title_id, 
    rt.title, 
    rt.production_year, 
    md.company_name, 
    md.keyword
FROM 
    RankedTitles rt
JOIN 
    MovieDetails md ON rt.title_id = md.movie_id
WHERE 
    rt.rank = 1
GROUP BY 
    rt.title_id, 
    rt.title, 
    rt.production_year, 
    md.company_name, 
    md.keyword
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
