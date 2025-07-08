
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
MovieCompanies AS (
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
CombinedData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.actor_name,
        cd.role_name,
        comp.company_name,
        comp.company_type,
        rm.keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        MovieCompanies comp ON rm.movie_id = comp.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    LISTAGG(DISTINCT actor_name || ' (' || role_name || ')', ', ') WITHIN GROUP (ORDER BY actor_name) AS actors,
    LISTAGG(DISTINCT company_name || ' (' || company_type || ')', ', ') WITHIN GROUP (ORDER BY company_name) AS production_companies,
    LISTAGG(DISTINCT keyword, ', ') WITHIN GROUP (ORDER BY keyword) AS keywords
FROM 
    CombinedData
GROUP BY 
    movie_id, title, production_year
ORDER BY 
    production_year DESC, title;
