WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(cc.person_id) AS total_cast_members,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.person_id) DESC) as rank
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        total_cast_members
    FROM 
        RankedMovies
    WHERE 
        rank <= 5 -- Get top 5 movies per year
),
MovieKeywords AS (
    SELECT 
        mt.title,
        mk.keyword 
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(mk.keyword, 'No Keywords') AS keyword_info,
    fm.total_cast_members,
    CASE 
        WHEN fm.total_cast_members > 10 THEN 'Large'
        WHEN fm.total_cast_members BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Small'
    END AS cast_size_category
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON fm.title = mk.title
ORDER BY 
    fm.production_year ASC, 
    fm.total_cast_members DESC
OFFSET 5 ROWS 
FETCH NEXT 10 ROWS ONLY; 

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RankedMovies`: This CTE calculates the number of cast members for each movie per year and ranks them based on this count.
   - `FilteredMovies`: Selects the top 5 movies by total cast members for each year.
   - `MovieKeywords`: Joins movies with their keywords, allowing us to highlight keyword data linked to the movies.

2. **Main Query**:
   - The final selection retrieves movie titles, production years, keywords (handling NULLs with COALESCE), total cast members, and a derived column for the size of the cast.
   - The case statement categorizes movies based on the total cast size into "Large," "Medium," and "Small."

3. **Pagination**:
   - The query offsets the first 5 rows and fetches the next 10 rows, showcasing the use of pagination.

4. **Join Types**:
   - Utilizes LEFT JOIN to ensure that movies without keywords are still included.

5. **Complex Logic and Calculations**:
   - Includes a variety of constructs, such as window functions for ranking, complex predicates using CASE statements, and handling NULL logic with COALESCE.

This SQL query provides a robust performance benchmarking route, testing join orders, aggregation performance, and CTE handling while showcasing intricate SQL semantics.
