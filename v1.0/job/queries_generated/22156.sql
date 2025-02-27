WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        COUNT(ci.id) AS number_of_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, ak.name, rt.role
),
MoviesWithKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.production_year,
    rt.title AS movie_title,
    ar.actor_name,
    ar.role_name,
    mwk.keywords,
    COALESCE(ar.number_of_roles, 0) AS role_count
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoles ar ON rt.title_id = ar.movie_id AND ar.number_of_roles > 1
LEFT JOIN 
    MoviesWithKeywords mwk ON rt.title_id = mwk.movie_id
WHERE 
    (rt.production_year IS NOT NULL)
    AND (rt.title_rank = 1 OR ar.role_name IS NOT NULL)
    AND (rt.production_year BETWEEN 2000 AND 2023 OR ar.actor_name LIKE 'John%')
ORDER BY 
    rt.production_year DESC, 
    rt.title;

### Explanation of the Query Components:

1. **Common Table Expressions (CTEs):**
   - `RankedTitles`: Ranks movie titles per production year.
   - `ActorRoles`: Aggregates and counts distinct roles played by actors in movies.
   - `MoviesWithKeywords`: Aggregates keywords associated with each movie.

2. **Outer Joins:**
   - Left joins are used to gather actor roles and movie keywords, even if there are none.

3. **String Aggregation:**
   - Uses `STRING_AGG` to concatenate keywords for each movie.

4. **Window Functions:**
   - ROW_NUMBER() is used in CTE `RankedTitles` to order titles.

5. **Complicated Predicates:**
   - The WHERE clause includes multiple conditions including:
      - Null checks and checking against ranks and role counts.
      - Wildcards to match actor names starting with 'John'.

6. **NULL Logic:**
   - `COALESCE` manages potential NULL values in role counts.

7. **Set Operators and Order:**
   - The query prioritizes certain titles and structures the results, displaying latest productions first. 

8. **Bizarre SQL Semantics:**
   - Conditional indexing by ranking and role must align with NULL checks in outer joins in generating the final output. 

This query is designed for performance benchmarking, particularly looking at complex interactions between various entities in the movie database schema.
