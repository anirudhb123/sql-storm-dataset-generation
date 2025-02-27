WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
DirectorMovieCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COALESCE(SUM(CASE WHEN rp.kind = 'Director' THEN 1 ELSE 0 END), 0) AS director_count
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rp ON ci.role_id = rp.id
    GROUP BY 
        ci.movie_id
),
KeywordStats AS (
    SELECT 
        mk.movie_id, 
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    d.total_cast,
    d.director_count,
    k.keyword_count,
    CASE 
        WHEN r.year_rank = 1 THEN 'Latest Movie'
        ELSE 'Older Movie'
    END AS movie_rank_category
FROM 
    RankedMovies r
LEFT JOIN 
    DirectorMovieCounts d ON r.movie_id = d.movie_id
LEFT JOIN 
    KeywordStats k ON r.movie_id = k.movie_id
WHERE 
    r.production_year >= (SELECT MAX(production_year) - 10 FROM aka_title)
    AND (d.total_cast IS NULL OR d.total_cast > 0)
ORDER BY 
    r.production_year DESC, r.title
FETCH FIRST 100 ROWS ONLY;

This SQL query is structured to benchmark performance by utilizing several advanced SQL constructs:

1. **Common Table Expressions (CTEs)**: Three CTEs (`RankedMovies`, `DirectorMovieCounts`, and `KeywordStats`) are defined to break down the query into smaller, manageable parts.

2. **Window Functions**: The `RANK()` function is used to rank movies by production year.

3. **Outer Joins**: LEFT JOINs are used to count directors and keywords, allowing for NULL handling in the results.

4. **Correlated Subqueries**: Used in the `WHERE` clause to filter for movies produced in the last 10 years.

5. **Complicated CASE Expressions**: A conditional column is added to categorize movies into 'Latest Movie' or 'Older Movie'.

6. **NULL Logic**: Uses `COALESCE` to ensure counts return valid integers even when no directors or keywords are associated with a movie.

7. **Complex predicates**: Multiple conditions in the `WHERE` clause ensure data integrity and relevancy.

8. **Limiting Rows**: `FETCH FIRST 100 ROWS ONLY` retrieves a subset of the resultant data for efficiency.

This query can serve as a benchmark for performance testing and optimization across various database engines by measuring execution times for its various components and complexity.
