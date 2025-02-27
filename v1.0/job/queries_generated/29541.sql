WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        mk.keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    COALESCE(md.keywords, 'No keywords') AS keywords
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;

This SQL query performs the following operations:

1. **RankedMovies Common Table Expression (CTE)**: It selects movies with their cast counts and ranks them within each production year.

2. **TopMovies CTE**: It filters to get the top 5 movies by cast count for each year.

3. **MovieKeywords CTE**: It aggregates keywords for the movies in the top 5.

4. **MovieDetails CTE**: It combines movie details with their corresponding keywords.

5. **Final Selection**: It retrieves the title, production year, cast count, and keywords, ordered by production year (newest first) and cast count (highest first). 

This benchmark tests the efficiency of string aggregation and joins across multiple tables related to movie data.
