WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keywords,
        COALESCE(ct.kind, 'Unknown Type') AS company_type,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS row_num
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year IS NOT NULL
),
RankedMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY production_year DESC, title) AS year_rank
    FROM 
        RecursiveMovieCTE
),
FilteredMovies AS (
    SELECT 
        year_rank,
        title,
        production_year,
        keywords,
        company_type
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 10
    AND 
        (keywords IS NOT NULL OR company_type != 'No Companies')
)
SELECT 
    R.title,
    R.production_year,
    CASE 
        WHEN R.keywords = 'No Keywords' THEN 'N/A' 
        ELSE R.keywords 
    END AS finalized_keywords,
    R.company_type,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = R.movie_id 
     AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre'))
     AS genre_count
FROM 
    FilteredMovies R
WHERE 
    EXISTS (SELECT 1 
            FROM cast_info ci 
            WHERE ci.movie_id = R.movie_id 
            AND ci.person_role_id IN (SELECT id FROM role_type WHERE role = 'Director'))
ORDER BY 
    R.production_year DESC, R.title;

### Explanation:
1. **Common Table Expressions (CTEs)**: The query uses multiple CTEs. The first CTE (`RecursiveMovieCTE`) gathers essential movie details along with associated keywords and company types. This includes outer joins to ensure all movies are collected even if they have no keywords or associated companies.

2. **Window Functions**: The `ROW_NUMBER()` function in `RecursiveMovieCTE` is applied to rank movies based on their production years. Further, `RANK()` in `RankedMovies` allows easy filtering of the top 10 recent movies.

3. **Filtered Logic**: In `FilteredMovies`, complex predicates filter out unnecessary records based on the presence of keywords or company types.

4. **Subquery for Counts**: A correlated subquery counts the number of genre information types associated with each movie, emphasizing the flexibility of subqueries.

5. **Final Selection**: The final selection pulls from the filtered movies, applying additional null logic to format the keywords properly.

6. **Conditional Logic**: It returns 'N/A' for keywords that are 'No Keywords'.

7. **Existential Check**: The `EXISTS` clause ensures that only movies with directors are returned.

This query provides an elaborate example of advanced SQL features, perfect for performance benchmarking against various data processing scenarios.
