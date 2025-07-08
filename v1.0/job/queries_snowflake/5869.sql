WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS company_type,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) as rn
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year >= 2000
        AND c.kind IS NOT NULL
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    rm.company_type,
    rm.role_name
FROM 
    RankedMovies rm
WHERE 
    rm.rn = 1
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title;
