
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
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
        c.country_code = 'USA'
)
SELECT 
    rt.title,
    rt.production_year,
    mc.cast_count,
    mc.actor_names,
    cm.company_name,
    cm.company_type
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieCast mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    CompanyMovies cm ON rt.title_id = cm.movie_id
WHERE 
    rt.title_rank <= 5
GROUP BY 
    rt.title, 
    rt.production_year, 
    mc.cast_count, 
    mc.actor_names, 
    cm.company_name, 
    cm.company_type
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC
LIMIT 50;
