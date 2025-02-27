WITH RECURSIVE 
    RankedTitles AS (
        SELECT 
            t.id AS title_id,
            t.title,
            t.production_year,
            ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
        FROM 
            aka_title t
    ),
    MovieScores AS (
        SELECT 
            t.title,
            t.production_year,
            COUNT(mk.keyword) AS keyword_count,
            COUNT(DISTINCT c.person_id) AS cast_count,
            (EXTRACT(YEAR FROM CURRENT_DATE) - t.production_year) AS age
        FROM 
            RankedTitles t
        JOIN 
            movie_keyword mk ON t.id = mk.movie_id
        JOIN 
            cast_info c ON t.id = c.movie_id
        GROUP BY 
            t.title, t.production_year
    ),
    HighScoreMovies AS (
        SELECT 
            title, 
            production_year, 
            keyword_count, 
            cast_count, 
            age,
            RANK() OVER (ORDER BY keyword_count DESC, cast_count DESC) AS rank
        FROM 
            MovieScores
        WHERE 
            age < 5
    )
SELECT 
    m.title,
    m.production_year,
    m.keyword_count,
    m.cast_count,
    m.age
FROM 
    HighScoreMovies m
WHERE 
    rank <= 10
    OR 
    (m.keyword_count > 15 AND m.cast_count > 5)
ORDER BY 
    m.production_year DESC, 
    m.keyword_count DESC;

### Explanation:
1. **Common Table Expressions (CTEs)** are used to generate intermediate results.
   - `RankedTitles`: This CTE ranks titles based on production year and title.
   - `MovieScores`: This CTE aggregates data to count keywords and cast for each title while calculating the movie's age.
   - `HighScoreMovies`: It ranks movies based on keyword and cast counts, filtering for recent films (less than 5 years old).

2. **Window Functions** like `ROW_NUMBER()` and `RANK()` provide advanced ranking capabilities for our titles and scores.

3. **JOIN Operations**: The query uses JOINs to bring together related data from multiple tables (`aka_title`, `movie_keyword`, and `cast_info`).

4. **Complex Filtering**: The main SELECT statement filters to top-ranked movies by keywords and cast, along with additional conditions on counts, capitalizing on the expressive power of SQL.

5. **Ordering**: Finally, results are ordered by production year and keyword count, providing a clear view of the best-performing recent titles. 

This query structure helps benchmark the performance of complex SQL queries involving multiple features such as correlated subqueries, CTEs, and window functions.
