
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_description,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') AS companies,
        LISTAGG(DISTINCT ct.kind, ', ') AS types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_description,
    ar.role_count,
    mk.keywords,
    cd.companies,
    cd.types
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.title_id = ar.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.title_id = mk.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.title_id = cd.movie_id
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, rm.title ASC;
