WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL 
        AND at.title IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        p.name AS actor_name,
        rt.role AS role_name,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, p.name, rt.role
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
CompanyTypeInfo AS (
    SELECT 
        mc.movie_id,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
),
ComplexAggregate AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ar.actor_count, 0) AS total_actors,
        COALESCE(mk.keywords, 'None') AS movie_keywords,
        COALESCE(cti.company_count, 0) AS total_companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        CompanyTypeInfo cti ON rm.movie_id = cti.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    total_actors,
    movie_keywords,
    total_companies,
    CASE 
        WHEN total_actors > 5 THEN 'High Actor Cast'
        WHEN total_actors BETWEEN 2 AND 5 THEN 'Medium Actor Cast'
        ELSE 'Low Actor Cast'
    END AS actor_cast_category
FROM 
    ComplexAggregate
WHERE 
    total_companies >= (SELECT AVG(total_companies) FROM ComplexAggregate)
ORDER BY 
    production_year DESC, total_actors DESC, title ASC;
