WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    WHERE 
        t.production_year >= 2000
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        c.movie_id,
        r.role 
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    ai.name AS actor_name,
    cd.company_name,
    cd.company_type
FROM 
    RankedMovies rm
JOIN 
    ActorInfo ai ON rm.movie_id = ai.movie_id
JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rn <= 3
ORDER BY 
    rm.production_year DESC, 
    ai.name;
