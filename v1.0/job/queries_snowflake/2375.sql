
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
CompanyTitles AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) OVER (PARTITION BY mc.movie_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FinalSelection AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_name,
        ar.role_name,
        ct.company_name,
        ct.company_type,
        ar.total_actors,
        ct.total_companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        CompanyTitles ct ON rm.movie_id = ct.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    movie_id,
    title,
    production_year,
    LISTAGG(DISTINCT actor_name, ', ') AS actors,
    LISTAGG(DISTINCT role_name, ', ') AS roles,
    LISTAGG(DISTINCT company_name, ', ') AS companies,
    LISTAGG(DISTINCT company_type, ', ') AS company_types,
    MAX(total_actors) AS max_actors,
    MAX(total_companies) AS max_companies
FROM 
    FinalSelection
GROUP BY 
    movie_id, title, production_year
ORDER BY 
    production_year DESC, title ASC;
