WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RANDOM()) AS random_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
FilteredActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    WHERE 
        LENGTH(a.name) > 5 OR a.name ILIKE '%Smith%'
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(ci.movie_id) >= 2
), 
CompanySummaries AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name || ' (' || ct.kind || ')') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    m.movie_id,
    m.movie_title,
    m.production_year,
    fa.name AS actor_name,
    fa.movie_count,
    cs.companies
FROM 
    RankedMovies m
LEFT JOIN 
    FilteredActors fa ON fa.movie_count > 2 AND m.movie_id IN (
        SELECT movie_id FROM cast_info ci WHERE ci.person_id = fa.person_id
    )
LEFT JOIN 
    CompanySummaries cs ON cs.movie_id = m.movie_id
WHERE 
    m.random_rank <= 10
ORDER BY 
    m.production_year DESC, 
    fa.movie_count DESC NULLS LAST;

### Explanation of the Query:
1. **Common Table Expressions (CTEs)**: 
   - `RankedMovies`: This CTE generates a list of movies, randomly ordering them each production year.
   - `FilteredActors`: This CTE filters actors based on the length of their name or if their name contains "Smith," and only includes those who have acted in at least two movies.
   - `CompanySummaries`: This CTE aggregates the names and types of companies associated with each movie into a single string.

2. **Main SELECT Statement**: 
   - Joins the `RankedMovies` with filtered actors who have performed in more than two movies, and company summaries.
   - Applies a filter to grab only the top ten movies based on the random ranking generated in the first CTE.
   - Orders results by the production year in descending order and the count of movies in which actors appeared, handling NULLs correctly.

This query incorporates various SQL features, including window functions, CTEs, and multiple JOINs, while maintaining a focus on performance benchmarking by limiting the number of returned results and employing a random ranking strategy.
