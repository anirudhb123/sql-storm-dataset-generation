WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.title_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    CONCAT('[', COALESCE(mk.keywords, 'No Keywords'), ']') AS keywords,
    CASE WHEN tm.production_year IS NOT NULL THEN 'Released' ELSE 'Unreleased' END AS release_status,
    (SELECT COUNT(*) FROM person_info pi WHERE pi.info_type_id = 1 AND pi.person_id IN (
        SELECT DISTINCT person_id FROM cast_info WHERE movie_id = tm.title_id
    )) AS num_directors,
    COALESCE(NULLIF(tm.cast_count, 0), 1) AS adjusted_cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title_id = mk.title_id
WHERE 
    (tm.cast_count > 2 OR 
     (tm.cast_count = 2 AND (tm.production_year % 2 = 0))) 
    AND EXISTS (
        SELECT 1 FROM complete_cast cc WHERE cc.movie_id = tm.title_id 
        AND cc.status_id = (SELECT id FROM info_type WHERE info = 'Completed')
    )
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC
LIMIT 10;

This complex SQL query performs several operations, including the following:

1. **Common Table Expressions (CTEs)**: CTEs are used to break down the problem into manageable parts:
   - `RankedMovies`: Ranks movies by the number of distinct cast members per production year.
   - `TopMovies`: Selects the top 5 movies for each production year based on rank.
   - `MovieKeywords`: Aggregates keywords for each movie title.

2. **Aggregation and Window Functions**: It uses window functions to rank movies by cast count and aggregate keywords for easy viewing.

3. **Outer Joins and EXISTS**: It performs a left join to gather keywords and checks for specific conditions with a correlated subquery.

4. **String Concatenation**: The concatenation of keywords into a single string using `STRING_AGG`.

5. **Conditional Expressions**: It checks the production year to assign a release status and adjusts the cast count, including logic for handling potential division by zero.

6. **Complex Filtering**: Filters the results based on intricate conditions relating to the movie's cast count, ensuring certain rules apply.

7. **NULL Logic**: It utilizes `COALESCE` and `NULLIF` functions to handle potential NULL values. 

This query likely runs across large datasets and can stress-test the performance with the combination of sorts, filters, aggregations, and joins.
