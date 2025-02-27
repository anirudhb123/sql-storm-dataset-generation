WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, ak.name, rt.role
    HAVING 
        COUNT(*) > 1
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cs.company_count,
        cs.companies,
        ar.actor_name,
        ar.role_name
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyStats cs ON rm.movie_id = cs.movie_id
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    WHERE 
        rm.rank_in_year <= 5 
        OR (cs.company_count IS NULL AND rm.production_year < 2000)
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.companies, 'Unknown') AS companies,
    COALESCE(md.actor_name, 'No Actors') AS actor_name,
    COALESCE(md.role_name, 'Unspecified Role') AS role_name
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.title ASC
FETCH FIRST 100 ROWS ONLY;

-- Additional DEBUGGING LOGIC
-- This would normally not be present but helps to understand NULL handling
SELECT 
    md.title,
    CASE 
        WHEN md.production_year IS NULL THEN 'No Year Provided'
        ELSE md.production_year::text 
    END AS production_year,
    md.companies,
    md.actor_name,
    md.role_name
FROM 
    MovieDetails md
WHERE 
    md.actor_name IS NULL OR md.assigned_role IS NULL;
This SQL query employs multiple techniques including CTEs, window functions, and various JOIN operations. It demonstrates complex logic for summarizing movie data filtered by production year and company involvement while also investigating actors and their roles. The use of `COALESCE` ensures robust NULL handling, providing fallback values in case of missing data. The query also fetches limited results and introduces corner cases to observe how NULL values are processed, showcasing the importance of NULL logic in SQL.
