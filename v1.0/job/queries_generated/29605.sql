WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        c.name AS company_name, 
        r.role AS actor_role, 
        p.name AS actor_name, 
        ROW_NUMBER() OVER(PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        a.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        company_name, 
        actor_role, 
        actor_name
    FROM 
        RankedMovies
    WHERE 
        rn = 1
)
SELECT 
    production_year,
    STRING_AGG(DISTINCT title, ', ' ORDER BY title) AS titles,
    STRING_AGG(DISTINCT actor_name || ' (' || actor_role || ')', ', ' ORDER BY actor_name) AS actors,
    STRING_AGG(DISTINCT company_name, ', ' ORDER BY company_name) AS companies
FROM 
    FilteredMovies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC
LIMIT 10;
