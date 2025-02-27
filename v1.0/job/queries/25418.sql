WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        k.keyword AS keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MovieCast AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        r.role AS actor_role
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id, 
        co.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT mc.actor_name || ' (' || mc.actor_role || ')', ', ') AS cast,
    STRING_AGG(DISTINCT cm.company_name || ' (' || cm.company_type || ')', ', ') AS companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.rn <= 5 
GROUP BY 
    rm.movie_id, rm.movie_title, rm.production_year
ORDER BY 
    rm.production_year DESC, rm.movie_title;