WITH RankedMovies AS (
    SELECT 
        title.movie_id, 
        title.title, 
        title.production_year,
        RANK() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank_by_cast
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.movie_id, title.title, title.production_year
),
DetailedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(count_keywords.keyword_count, 0) AS keyword_count,
        COALESCE(count_companies.company_count, 0) AS company_count,
        COALESCE(count_actors.actor_count, 0) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(*) AS keyword_count 
        FROM 
            movie_keyword 
        GROUP BY 
            movie_id
    ) count_keywords ON rm.movie_id = count_keywords.movie_id
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(DISTINCT company_id) AS company_count 
        FROM 
            movie_companies 
        GROUP BY 
            movie_id
    ) count_companies ON rm.movie_id = count_companies.movie_id
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(DISTINCT person_id) AS actor_count 
        FROM 
            cast_info 
        GROUP BY 
            movie_id
    ) count_actors ON rm.movie_id = count_actors.movie_id
)
SELECT 
    d.title, 
    d.production_year, 
    d.keyword_count,
    d.company_count,
    d.actor_count
FROM 
    DetailedMovies d
WHERE 
    d.rank_by_cast <= 5
UNION 
SELECT 
    t.title, 
    t.production_year, 
    0 AS keyword_count, 
    0 AS company_count, 
    0 AS actor_count
FROM 
    title t
WHERE 
    t.production_year = (SELECT MAX(production_year) FROM title) 
    AND NOT EXISTS (
        SELECT 1 
        FROM cast_info ci WHERE ci.movie_id = t.id
    )
ORDER BY 
    production_year DESC, 
    title ASC;

This SQL query achieves a few interesting points:

1. **Common Table Expressions (CTEs)**: Two CTEs are used:
   - `RankedMovies`: Ranks movies based on the number of distinct actors in each movie, grouped by production year.
   - `DetailedMovies`: Gathers detailed statistics about keyword counts, company counts, and actor counts for the movies from the `RankedMovies` CTE.

2. **LEFT JOINs**: Used to gather additional properties (keywords, companies, actor counts) for each movie while retaining movies even if these properties do not exist (NULL values will be handled).

3. **COALESCE**: Ensures that NULL values for keyword count, company count, and actor count are represented as zero.

4. **UNION**: Combines results for the top-ranked movies and for movies from the most recent year that have no associated cast (actors), categorized as "orphan" movies.

5. **Complicated predicates**: Uses both EXISTS and NON-EXISTS to filter orphan movies.

6. **Window Function**: Utilizes `RANK()` to handle ranking within groups, showcasing advanced analytical capabilities.

7. **Sorting**: Final results are ordered by `production_year` and then `title`, allowing for both easy readability and historical analysis.

This query reflects comprehensive performance testing through the depth and complexity of the SQL constructs used, while capturing interesting semantic behaviors.
