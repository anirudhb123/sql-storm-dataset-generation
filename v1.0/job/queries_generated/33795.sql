WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.movie_id,
        ca.person_id,
        1 AS depth
    FROM 
        cast_info ca
    WHERE 
        ca.person_role_id = (SELECT id FROM role_type WHERE role = 'actor')
    
    UNION ALL
    
    SELECT 
        ca.movie_id,
        ca.person_id,
        ah.depth + 1
    FROM 
        cast_info ca
    INNER JOIN 
        ActorHierarchy ah ON ca.movie_id = ah.movie_id
    WHERE 
        ca.person_role_id IS NOT NULL
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ka.name AS actor_name,
        COUNT(DISTINCT mc.company_id) AS production_company_count,
        MAX(mi.info) AS more_info
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, ka.name
),
RankedMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.production_company_count DESC) AS rank
    FROM 
        MovieDetails md
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_name,
    COALESCE(rm.production_company_count, 0) AS production_company_count,
    rm.more_info
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year, 
    rm.production_company_count DESC;

This SQL query consists of several sophisticated components:
- A Recursive CTE (`ActorHierarchy`) to explore the relationships among actors participating in the same movie.
- A second CTE (`MovieDetails`) gathering details from multiple tables using LEFT JOINs to ensure information is maintained even if some join conditions fail.
- The use of `ROW_NUMBER` as a window function to rank movies by the number of production companies associated with them, grouped by the year of production.
- Finally, it selects the top 5 movies per production year, sorted by the number of production companies they feature, while handling NULLs gracefully with `COALESCE`.
