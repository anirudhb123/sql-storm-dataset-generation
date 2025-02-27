WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND (k.keyword ILIKE '%action%' OR k.keyword ILIKE '%drama%')
),
ActorRoles AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT mc.company_type_id) AS company_types_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
DistinctProductionYears AS (
    SELECT 
        DISTINCT production_year
    FROM 
        aka_title
    WHERE 
        production_year IS NOT NULL
),
NullRoleActors AS (
    SELECT 
        DISTINCT c.person_id
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role IS NULL
)

SELECT 
    rm.title,
    rm.production_year,
    ar.movie_count,
    ar.roles,
    cd.companies,
    cd.company_types_count,
    CASE 
        WHEN ar.movie_count IS NULL THEN 'No movies'
        ELSE 'Has movies'
    END AS movies_status,
    CASE 
        WHEN rm.production_year IN (SELECT * FROM DistinctProductionYears) THEN 'Film year is valid'
        ELSE 'Unknown production year'
    END AS production_year_status,
    STRING_AGG(DISTINCT ar.person_id::text, ', ') FILTER (WHERE ar.movie_count IS NULL) AS actors_with_no_roles
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON ar.movie_count > 0 
LEFT JOIN 
    CompanyDetails cd ON rm.title_id = cd.movie_id
WHERE 
    rm.rn = 1
GROUP BY 
    rm.title, rm.production_year, ar.movie_count, ar.roles, cd.companies, cd.company_types_count
ORDER BY 
    COALESCE(rm.production_year, 0) DESC, 
    rm.title ASC
LIMIT 100;
