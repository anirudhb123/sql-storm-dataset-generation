WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        rt.role,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        t.production_year IS NOT NULL 
        AND LENGTH(t.title) > 5
    GROUP BY 
        t.id, t.title, t.production_year, rt.role
),
FilterMovies AS (
    SELECT 
        *,
        CASE
            WHEN cast_count > 10 THEN 'High'
            WHEN cast_count BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS cast_level
    FROM 
        RankedMovies
    WHERE 
        rn = 1
),
TopMoviesWithKeywords AS (
    SELECT 
        fm.title,
        fm.production_year,
        fm.cast_level,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY fm.title ORDER BY k.keyword) AS keyword_rank
    FROM 
        FilterMovies fm
    LEFT JOIN 
        movie_keyword mk ON fm.title = (SELECT title FROM aka_title WHERE movie_id = mk.movie_id)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    t.title,
    t.production_year,
    t.cast_level,
    STRING_AGG(k.keyword, ', ') AS keywords
FROM 
    TopMoviesWithKeywords t
WHERE 
    t.keyword_rank <= 5 OR t.cast_level = 'High'
GROUP BY 
    t.title, t.production_year, t.cast_level
ORDER BY 
    t.production_year DESC,
    t.cast_level DESC;
This SQL query retrieves a list of movies based on the following criteria:

- It uses CTEs (common table expressions) to rank movies based on their cast size and associate them with keywords.
- It performs LEFT JOINs to ensure all movies are included, even if they don't have cast or keywords.
- It uses the `ROW_NUMBER()` window function to rank entries within partitions (movies based on cast size and keywords).
- A case expression categorizes movies according to their cast size ('High', 'Medium', 'Low').
- The final selection groups movies by title and production year, aggregating their keywords into a single string.
- It includes complex predicates to filter for movies with specific keyword rank or cast size, showcasing the combination of various SQL features.
