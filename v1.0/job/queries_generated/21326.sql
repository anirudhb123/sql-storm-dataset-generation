WITH RankedMovies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CastCounts AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS actor_count,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS known_roles
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(c.actor_count, 0) AS actor_count,
        COALESCE(c.known_roles, 0) AS known_roles,
        (SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
         FROM movie_keyword mk 
         JOIN keyword k ON mk.keyword_id = k.id 
         WHERE mk.movie_id = m.id) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        CastCounts c ON m.id = c.movie_id
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.actor_count,
        md.keywords,
        CASE 
            WHEN md.actor_count > 0 THEN md.keywords 
            ELSE 'No actors present' 
        END AS adaptable_keywords
    FROM 
        MovieDetails md
    WHERE 
        md.actor_count > 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.keywords,
    tv.title_rank,
    CASE 
        WHEN tm.adaptable_keywords IS NULL THEN 'Keywords not available' 
        ELSE tm.adaptable_keywords 
    END AS final_keywords
FROM 
    TopMovies tm
LEFT JOIN 
    RankedMovies tv ON tm.movie_id = tv.title_id
WHERE 
    tv.title_rank <= 10 OR tm.actor_count >= 10
ORDER BY 
    tm.actor_count DESC, 
    tv.production_year DESC NULLS LAST;

### Explanation of the Query
1. **CTEs**: 
   - `RankedMovies`: This CTE ranks the movies by title within each production year using the `RANK()` window function.
   - `CastCounts`: This counts the number of actors per movie and counts known roles, distinguishing between known and unknown roles through conditional counting.
   - `MovieDetails`: This aggregates movie details including keywords into a single string using `STRING_AGG()`. It also uses `COALESCE` to handle any NULL values effectively.
   - `TopMovies`: Filters to include only movies with more than 5 actors and modifies keywords based on conditions about the actor count.

2. **JOINs**: 
   - The main query joins `TopMovies` with `RankedMovies` to get additional ranking information about the titles.

3. **Conditional Logic**: 
   - Checks presence of actors and adapts keywords accordingly, using `CASE` statements to manage different conditions of actor presence and keyword aggregation.

4. **NULL Handling**: 
   - Careful handling of NULL values in keywords, actor counts, and ranks ensures robust outputs that provide clear insights.

5. **Setting Limits and Ordering**: 
   - The final results are filtered to include only the best-performing movies, ordered by actor count and production year while ensuring NULLs in years appear last.

This query showcases various SQL constructs and aims to provide a comprehensive overview of movie data while addressing semantics and NULL conditions creatively.
