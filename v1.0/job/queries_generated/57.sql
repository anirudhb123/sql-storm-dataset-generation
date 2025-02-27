WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title, 
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
), ActorRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
), CompanyDetails AS (
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
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    ar.role,
    ar.actor_count,
    cd.company_name,
    cd.company_type,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.title_rank <= 5 
ORDER BY 
    rm.production_year DESC, 
    rm.title;
