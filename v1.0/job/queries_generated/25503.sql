WITH MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        title m 
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id
),
CompanyRoles AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_roles
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        title mt ON mc.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT r.role, ', ') AS actor_roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
CombinedData AS (
    SELECT 
        t.title,
        t.production_year,
        mk.keywords,
        cr.company_roles,
        ar.actor_roles
    FROM 
        title t
    LEFT JOIN 
        MovieKeywords mk ON t.id = mk.movie_id
    LEFT JOIN 
        CompanyRoles cr ON t.id = cr.movie_id
    LEFT JOIN 
        ActorRoles ar ON t.id = ar.movie_id
)
SELECT 
    title,
    production_year,
    keywords,
    company_roles,
    actor_roles
FROM 
    CombinedData
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC;
