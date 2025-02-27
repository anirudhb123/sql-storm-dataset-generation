WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.role_id) AS role_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
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
    rm.title,
    rm.production_year,
    COALESCE(ar.roles, 'No Roles') AS actor_roles,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(ci.company_names, 'No Companies') AS production_companies,
    COALESCE(ci.company_types, 'No Types') AS production_types,
    (SELECT COUNT(*) FROM cast_info c WHERE c.movie_id = rm.title_id) AS total_cast,
    (SELECT COUNT(*) 
     FROM aka_name an 
     WHERE an.person_id IN (SELECT DISTINCT person_id FROM cast_info WHERE movie_id = rm.title_id) 
     AND an.name ILIKE '%John%') AS johns_in_movie
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.title_id IN (SELECT DISTINCT movie_id FROM cast_info WHERE person_id = ar.person_id)
LEFT JOIN 
    MovieKeywords mk ON rm.title_id = mk.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.title_id = ci.movie_id
WHERE 
    rm.rn <= 5 
    AND (rm.production_year < 2000 OR rm.production_year IS NULL)
ORDER BY 
    rm.production_year DESC, rm.title;
