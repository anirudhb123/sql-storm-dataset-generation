WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorsInMovies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank,
        c.nr_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
CompanyRoles AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS role_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
)
SELECT 
    rm.title,
    rm.production_year,
    a.actor_name,
    a.nr_order,
    COALESCE(c.company_name, 'Independent') AS production_company,
    COALESCE(c.role_count, 0) AS company_roles,
    (SELECT COUNT(DISTINCT m.keyword) 
     FROM movie_keyword m 
     WHERE m.movie_id = rm.movie_id) AS keyword_count,
    NULLIF(rm.total_movies, 0) AS total_movies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsInMovies a ON rm.movie_id = a.movie_id AND a.actor_rank <= 3
LEFT JOIN 
    CompanyRoles c ON rm.movie_id = c.movie_id
WHERE 
    rm.year_rank = 1
    AND (c.company_type IS NULL OR c.company_type <> 'Independent')
ORDER BY 
    rm.production_year DESC, 
    rm.title,
    a.nr_order
LIMIT 100;

This query performs the following:

1. **Common Table Expressions (CTEs)** to segment the data.
   - `RankedMovies` ranks movies by production year and title, to find the first movie in each production year.
   - `ActorsInMovies` captures the top three actors in each movie based on alphabetical order of their names.
   - `CompanyRoles` aggregates company information per movie, counting roles.

2. **LEFT JOINs** link the main CTE (`RankedMovies`) to the actor and company data while providing defaults if data is missing (e.g., 'Independent' for companies).

3. **Correlated subquery** counts distinct keywords for each movie being monitored.

4. **COALESCE and NULLIF** functions handle NULL values sensibly, ensuring that the output makes sense even when certain relationships are missing.

5. **Bizarre semantics** are incorporated with grouping and conditions that might not usually appear in simpler queries (e.g., checking if a company type is 'Independent').

6. **Comprehensive filtering** and ordering to ensure a focused but rich dataset is returned, limited to 100 results for performance benchmarking.
