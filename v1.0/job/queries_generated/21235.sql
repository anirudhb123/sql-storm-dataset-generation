WITH MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_position,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(AVG(NULLIF(mk.keyword, '')), 'No keywords') AS average_keyword_length,
        COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind = 'Production') AS production_companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        m.id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_type,
        COUNT(*) OVER (PARTITION BY c.movie_id, r.role) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    mc.actor_name,
    mc.actor_position,
    mc.total_actors,
    ar.role_type,
    ar.role_count,
    md.average_keyword_length,
    md.production_companies
FROM 
    MovieDetails md
LEFT JOIN 
    MovieCast mc ON md.movie_id = mc.movie_id
LEFT JOIN 
    ActorRoles ar ON md.movie_id = ar.movie_id
WHERE 
    (md.production_year >= 2000 OR md.average_keyword_length LIKE '%keyword%')
    AND (ar.role_count IS NULL OR ar.role_count > 1)
ORDER BY 
    md.production_year DESC,
    mc.actor_position
LIMIT 100;

### Query Breakdown:
1. **CTE `MovieCast`**: This CTE collects movie IDs, actor names, their position in the cast, and the total number of actors for each movie using window functions.
   
2. **CTE `MovieDetails`**: This aggregates movie details including title, production year, average keyword length, and counts the number of production companies linked to the movie, employing various JOINs and conditional aggregation.

3. **CTE `ActorRoles`**: This retrieves the role type of the actors along with their respective counts per movie using a JOIN with the `role_type` to provide context about the actor's position across multiple roles.

4. **Final Selection**: The main SELECT statement combines these CTEs, applying filters for production year and role counts, and includes ordering and limits to ensure it retrieves the top 100 results based on certain criteria.

5. **Usage of `NULL`, `COALESCE`, and `FILTER`**: This introduces complexities such as handling NULL values, aggregating only valid entries, and implementing quirky SQL semantics. 

This query is designed to illustrate performance in terms of JOINs, GROUP BY, and complex predicates, especially in large datasets using the Join Order Benchmark schema.
