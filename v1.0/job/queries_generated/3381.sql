WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
CompanyInfo AS (
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
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(DISTINCT ar.actor_name) AS actor_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        STRING_AGG(DISTINCT c.company_name, ', ') AS companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        KeywordCount kc ON rm.movie_id = kc.movie_id
    LEFT JOIN 
        CompanyInfo c ON rm.movie_id = c.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    md.keyword_count,
    md.companies,
    CASE 
        WHEN md.actor_count > 10 THEN 'High'
        WHEN md.actor_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS popularity_category
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2023
    AND md.keyword_count > 2
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC;
