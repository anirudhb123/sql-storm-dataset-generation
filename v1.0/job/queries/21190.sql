WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT CONCAT(na.name, ' as ', rt.role), ', ') AS cast_details
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        aka_name na ON ci.person_id = na.person_id
    GROUP BY 
        ci.movie_id
),
CompanyInformation AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        MAX(CASE WHEN ct.kind = 'Production' THEN cn.name END) AS production_company
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        ar.actor_count,
        ar.cast_details,
        ci.companies,
        ci.production_company
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.title_id = ar.movie_id
    LEFT JOIN 
        CompanyInformation ci ON rm.title_id = ci.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    COALESCE(md.cast_details, 'No cast available') AS actors,
    COALESCE(md.companies, 'No companies available') AS companies,
    (
        SELECT 
            COUNT(DISTINCT k.keyword) 
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        WHERE 
            mk.movie_id = md.title_id
    ) AS keyword_count,
    CASE 
        WHEN md.actor_count IS NULL THEN 'N/A'
        WHEN md.actor_count = 0 THEN 'Zero Actors'
        ELSE 'Has Actors'
    END AS actor_status,
    CASE 
        WHEN md.production_company IS NULL THEN 'Independent'
        ELSE 'Produced by ' || md.production_company
    END AS production_status
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 1990 AND 2000
ORDER BY 
    md.actor_count DESC NULLS LAST, 
    md.production_year;
