WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year, k.keyword
),

TopKeywords AS (
    SELECT 
        keyword,
        COUNT(*) AS keyword_count
    FROM 
        RankedMovies
    GROUP BY 
        keyword
    ORDER BY 
        keyword_count DESC
    LIMIT 10
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    tk.keyword,
    tk.keyword_count
FROM 
    RankedMovies rm
JOIN 
    TopKeywords tk ON rm.keyword = tk.keyword
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;

### Explanation:
- The query calculates the number of cast members for each movie and ranks the movies based on their titles, production years, and associated keywords.
- The `RankedMovies` CTE aggregates data by title, production year, and keyword, determining the count of distinct cast members for each movie.
- The `TopKeywords` CTE selects the top 10 most frequently occurring keywords from the ranked movies.
- Finally, the main query selects detailed information about each top movie including title, production year, cast count, and keyword frequency, ordering the results by production year and cast count in descending order.
