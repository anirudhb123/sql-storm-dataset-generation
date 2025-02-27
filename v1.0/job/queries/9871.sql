WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        r.role AS actor_role,
        p.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY r.role) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        t.production_year > 2000
    AND 
        c.country_code = 'USA'
), FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        actor_role,
        actor_name
    FROM 
        RankedMovies
    WHERE 
        rank <= 3
)
SELECT 
    movie_title,
    production_year,
    company_name,
    STRING_AGG(DISTINCT actor_name || ' (' || actor_role || ')', ', ') AS actors
FROM 
    FilteredMovies
GROUP BY 
    movie_title, production_year, company_name
ORDER BY 
    production_year DESC, movie_title;
