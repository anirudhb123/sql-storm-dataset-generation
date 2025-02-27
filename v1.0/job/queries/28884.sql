
WITH MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),

CastInfo AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),

CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mi.movie_id,
    mi.movie_title,
    mi.production_year,
    ci.actor_names,
    ci.roles,
    comp.company_names,
    comp.company_types,
    mi.keywords
FROM 
    MovieInfo mi
LEFT JOIN 
    CastInfo ci ON mi.movie_id = ci.movie_id
LEFT JOIN 
    CompanyInfo comp ON mi.movie_id = comp.movie_id
WHERE 
    mi.production_year >= 2000
ORDER BY 
    mi.production_year DESC, 
    mi.movie_title;
