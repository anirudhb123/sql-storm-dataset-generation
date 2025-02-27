WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        year_rank <= 5
),
MovieInfoAndKeywords AS (
    SELECT 
        m.title,
        m.production_year,
        mi.info,
        k.keyword
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_info mi ON m.title = mi.info
    LEFT JOIN 
        movie_keyword mk ON m.production_year = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year,
        STRING_AGG(DISTINCT info, '; ') AS movie_info,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM 
        MovieInfoAndKeywords
    WHERE 
        info IS NOT NULL AND keyword IS NOT NULL
    GROUP BY 
        title, production_year
)

SELECT 
    fm.title,
    fm.production_year,
    fm.movie_info,
    fm.keywords,
    COALESCE(NULLIF(SUBSTRING(fm.keywords FROM '[^,]+'), ''), 'No Keywords') AS processed_keywords,
    COUNT(*) OVER () AS total_movies
FROM 
    FilteredMovies fm
WHERE 
    LENGTH(fm.title) > 10 -- Only consider titles longer than 10 characters
ORDER BY 
    fm.production_year DESC, 
    fm.title;

### Explanation:

1. **CTEs (Common Table Expressions)**:  
   - **RankedMovies**: This CTE computes the number of distinct cast members per movie and ranks them within their production year based on the total cast.
   - **TopMovies**: This CTE retrieves the top 5 movies for each production year based on the cast count from `RankedMovies`.
   - **MovieInfoAndKeywords**: Combines movie information and keywords associated with the top movies using outer joins to ensure movies are included even if they lack certain data.
   - **FilteredMovies**: Aggregates movie information and keywords into single fields, filtering out any NULL information.

2. **STRING_AGG**: Used to concatenate movie info and keywords with appropriate delimiters.

3. **COALESCE and NULLIF Logic**: This expression processes the keywords to replace empty strings with 'No Keywords', effectively demonstrating NULL handling.

4. **Window Function**: COUNT(*) OVER () calculates the total number of movies across the entire result set, providing a global count.

5. **Predicates**: It filters for movie titles longer than 10 characters, creating a peculiar edge case that only partially focuses on longer title lengths and potentially leaving out shorter but significant titles.

6. **Ordering**: The final result is ordered by production year and then by title, making it easier to read and analyze the output. 

This SQL query is both elaborate in its logic and utilizes various SQL constructs to demonstrate complex data manipulations across the specified schema.
