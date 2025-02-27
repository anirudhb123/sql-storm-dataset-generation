WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyMovements AS (
    SELECT 
        mc.movie_id,
        comp.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name comp ON mc.company_id = comp.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
DetailedMovieInfo AS (
    SELECT 
        rm.title,
        rm.production_year,
        cd.actor_name,
        cd.role_name,
        cm.company_name,
        cm.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        CompanyMovements cm ON rm.movie_id = cm.movie_id
)
SELECT 
    title,
    production_year,
    STRING_AGG(DISTINCT actor_name || ' as ' || role_name, ', ') AS actors_and_roles,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS production_companies
FROM 
    DetailedMovieInfo
GROUP BY 
    title, production_year
ORDER BY 
    production_year DESC, title;
