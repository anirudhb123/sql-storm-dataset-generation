WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
),
ActorRoles AS (
    SELECT
        c.movie_id,
        ca.person_id,
        ca.note AS role_note,
        COUNT(ca.id) OVER (PARTITION BY c.movie_id) AS total_roles
    FROM 
        cast_info c
    JOIN 
        aka_name ca ON ca.person_id = c.person_id
    WHERE 
        ca.name IS NOT NULL
),
TopActors AS (
    SELECT 
        ar.movie_id,
        COUNT(DISTINCT ar.person_id) AS unique_actors,
        MAX(ar.role_note) AS top_role
    FROM 
        ActorRoles ar
    GROUP BY 
        ar.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        mc.note IS NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ta.unique_actors,
    ta.top_role,
    cd.companies,
    cd.company_count
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON ta.movie_id = rm.movie_id
FULL OUTER JOIN 
    CompanyDetails cd ON cd.movie_id = rm.movie_id
WHERE 
    (ta.unique_actors > 5 OR cd.company_count > 2)
    AND rm.title_rank > 3
    AND (rm.production_year IS NOT NULL OR cd.companies IS NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC
LIMIT 100;

-- This query performs a complex benchmark test combining various advanced SQL concepts, such as:
-- - Common Table Expressions (CTEs) for modularity
-- - ROW_NUMBER for ranking movies by title within their production year
-- - Correlated subqueries involving COUNT and aggregation
-- - Outer joins to include movies without actors or companies
-- - String aggregation with GROUP_CONCAT for capturing all relevant company names
-- - Complex predicates involving NULL checks, counts, and filtering based on specific conditions
