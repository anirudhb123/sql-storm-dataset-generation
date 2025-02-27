WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(DISTINCT kc.keyword) OVER (PARTITION BY t.id) as keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.person_id,
        a.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY a.movie_id ORDER BY r.role) as role_order
    FROM 
        cast_info a
    JOIN 
        role_type r ON a.role_id = r.id
),
ActorStats AS (
    SELECT 
        ar.person_id,
        COUNT(DISTINCT ar.movie_id) AS movie_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        ActorRoles ar
    GROUP BY 
        ar.person_id
)

SELECT 
    rm.title,
    rm.production_year,
    as.person_id,
    as.movie_count,
    as.roles,
    CASE 
        WHEN rm.keyword_count > 10 THEN 'High Keywords'
        WHEN rm.keyword_count BETWEEN 5 AND 10 THEN 'Medium Keywords'
        ELSE 'Low Keywords'
    END AS keyword_rating,
    COALESCE(NULLIF(as.roles, ''), 'No roles listed') AS valid_roles
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorStats as ON rm.id = as.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, rm.title;

### Explanation:

1. **CTEs for organization**:
   - The CTE `RankedMovies` ranks movies by production year and also counts distinct keywords for each movie.
   - The CTE `ActorRoles` assigns a role order to each actor for each movie.
   - The CTE `ActorStats` aggregates information about actors and concatenates their roles. 

2. **Main Query**:
   - The main query selects details from the ranked movies, joined with actor statistics.
   - It includes a classification of keyword density using CASE statements.
   - Uses `COALESCE` and `NULLIF` to handle cases where roles may be NULL or empty, returning a default string in those situations.

3. **Sorting and Filtering**:
   - The results are filtered to only include the top 10 ranked movies by production year and ordered for clear output.
