WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

ActiveMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        (SELECT COUNT(DISTINCT mk.keyword) 
         FROM movie_keyword mk 
         WHERE mk.movie_id = rm.movie_id) AS keyword_count,
        (SELECT COUNT(DISTINCT mi.info) 
         FROM movie_info mi 
         WHERE mi.movie_id = rm.movie_id 
         AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Awards%')) AS awards_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
)

SELECT 
    am.title,
    am.production_year,
    am.cast_count,
    am.keyword_count,
    am.awards_count,
    COALESCE(ct.kind, 'Unknown') AS company_type,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    ActiveMovies am
LEFT JOIN 
    movie_companies mc ON am.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
GROUP BY 
    am.movie_id, am.title, am.production_year, am.cast_count, am.keyword_count, am.awards_count, ct.kind
ORDER BY 
    am.production_year DESC,
    am.rank
LIMIT 5
OFFSET (SELECT COUNT(*) FROM ActiveMovies) - 5;

### Explanation of the query:

1. **Common Table Expressions (CTEs)**:
    - **RankedMovies**: This CTE ranks movies by their cast count, focusing only on movies with a valid production year.
    - **ActiveMovies**: This filters the top 10 movies ranked by cast count and retrieves additional metrics such as keyword and awards counts. These counts are achieved through correlated subqueries.

2. **Complex SELECT**:
    - In the main query, various metrics are collected and aggregated including the title, production year, cast count, keyword count, and awards count.

3. **LEFT JOINs**:
    - These are used to gather additional company-related data about the movies, ensuring that if a movie has no associated company, it still appears in the results.

4. **STRING_AGG**:
    - This function aggregates company names into a single string, separated by commas.

5. **Handling NULLs**:
    - The `COALESCE` function provides a default value ('Unknown') for movies with no associated company type, addressing the potential NULL values.

6. **Dynamic OFFSET**:
    - The query dynamically calculates an offset for pagination by determining the total number of rows in ActiveMovies minus 5, ensuring the last page of results is targeted.

7. **Ordering and Limits**:
    - The results are ordered by production year in descending order and by rank, limiting the output to the last five records.

This SQL construct showcases various advanced SQL features while handling potential corner cases and leveraging multiple database capabilities.
