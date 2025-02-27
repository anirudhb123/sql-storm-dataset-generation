WITH RankedCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_actors,
        COALESCE(t.title, 'N/A') AS movie_title,
        COALESCE(t.production_year, 0) AS production_year,
        COALESCE(k.keyword, 'Unknown') AS keyword
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        aka_title t ON t.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = ci.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
),
ActorMovies AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS movies_count,
        AVG(production_year) AS avg_production_year
    FROM 
        RankedCast
    WHERE 
        actor_rank <= 3 AND total_actors > 5
    GROUP BY 
        actor_name
),
FilteredMovies AS (
    SELECT 
        movie_id,
        movie_title,
        AVG(avg_production_year) AS avg_production_age
    FROM 
        RankedCast
    GROUP BY 
        movie_id, movie_title
    HAVING 
        AVG(production_year) < 2000
)
SELECT 
    am.actor_name,
    am.movies_count,
    fm.movie_title,
    fm.avg_production_age
FROM 
    ActorMovies am
LEFT JOIN 
    FilteredMovies fm ON am.movies_count > 1
WHERE 
    am.avg_production_year IS NOT NULL
ORDER BY 
    am.movies_count DESC,
    fm.avg_production_age ASC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;

This complex SQL query does the following:
1. **CTEs (Common Table Expressions)**: It defines three CTEs (`RankedCast`, `ActorMovies`, and `FilteredMovies`) for organizing data about movie actors and their roles.
2. **Window Functions**: It utilizes `RANK()` and `COUNT()` to determine actor rankings and total counts per movie.
3. **Joins**: It performs both inner and left joins to gather information from multiple tables, including actor names, movie titles, and keywords.
4. **Filtering Criteria**: It filters actors with a rank of 3 or less and limits their appearances to movies with more than 5 actors.
5. **Aggregations**: It computes counts and averages, allowing for nuanced insights about actors and their movies.
6. **HAVING Clause**: It ensures that only movies with an average production year before 2000 are included in the secondary aggregation.
7. **Final Selection**: It selects records from `ActorMovies` and joins them to the `FilteredMovies` CTE based on specified conditions, applying an order and pagination (using OFFSET and FETCH) to refine the results.

This query explores obscure corner cases by using the COALESCE function to handle NULL values, as well as filtering and aggregation for unique insights into actors' filmography from the movie industry’s metadata.
