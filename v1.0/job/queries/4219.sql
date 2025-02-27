WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
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
CompanyInfo AS (
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
),
Keywords AS (
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
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ar.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(ar.role_name, 'No Role') AS role_name,
    COALESCE(ci.company_name, 'Independent') AS company_name,
    COALESCE(ci.company_type, 'N/A') AS company_type,
    COALESCE(kw.keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    Keywords kw ON rm.movie_id = kw.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    rm.production_year DESC, rm.movie_id;
