WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year, 
        a.name AS actor_name, 
        c.kind AS cast_type,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    WHERE 
        cn.country_code = 'USA'
        AND t.production_year >= 2000
)
SELECT 
    rt.title,
    rt.production_year,
    rt.actor_name,
    rt.cast_type
FROM 
    RankedTitles rt
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.actor_name;
