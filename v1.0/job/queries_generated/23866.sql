WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 5
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(c.id) AS total_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ar.actor_name || ' (' || ar.role_name || ' - ' || ar.total_roles || ')', ', ') AS actor_details
    FROM 
        TopMovies tm
    LEFT JOIN 
        ActorRoles ar ON tm.title_id = ar.movie_id
    JOIN 
        aka_title t ON tm.title_id = t.id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_details, 'No actors available') AS actor_details,
    (SELECT 
        COUNT(DISTINCT mk.keyword_id) 
     FROM 
        movie_keyword mk 
     INNER JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id 
     WHERE 
        mi.info LIKE '%Award%' 
        AND mk.movie_id = t.id) AS awards_count
FROM 
    MovieDetails md
LEFT JOIN 
    aka_title t ON md.title = t.title
ORDER BY 
    md.production_year DESC, md.title;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RankedMovies`: This CTE ranks titles by their production year and filters for those that have non-null values.
   - `TopMovies`: Selects the top 5 movies for each production year.
   - `ActorRoles`: Aggregates actor data by movie, counting how many times a role is played by an actor.
   - `MovieDetails`: Joins `TopMovies` with `ActorRoles` to compile the titles with their respective actors and roles.

2. **Main Query**:
   - Selects from `MovieDetails`, incorporating a subquery for counting distinct keywords related to "Awards" specifically.
   - Uses `COALESCE` to handle cases where actor details might not be available.

3. **Join Types**:
   - Utilizes both LEFT JOINs and INNER JOINs to demonstrate different join behaviors, including outer join semantics.

4. **String Aggregation**:
   - String details of actors and their roles are concatenated using `STRING_AGG`, showing a complex expression.

5. **Correlation Subqueries**:
   - Notably found in the awards count, which references the outer query context.

6. **Handling of NULL Logic**:
   - Treatment of NULLs where `COALESCE` is employed to provide a clear default message.

7. **Ordering**:
   - The final output is ordered by production year in descending order and then by title, providing clear and organized results. 

This query showcases various SQL concepts and constructs, aiming for complexity and performance benchmarking in a real-world-like scenario.
