WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        COALESCE(STRING_AGG(DISTINCT c.name, ', '), 'No Cast') AS cast_names,
        COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No Keywords') AS keywords,
        COUNT(mk.keyword_id) AS keyword_count,
        MAX(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE -1 END) AS production_year
    FROM 
        movie_keyword mk
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    JOIN 
        aka_title t ON mk.movie_id = t.id
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    md.cast_names,
    md.keywords,
    md.keyword_count,
    RANK() OVER (ORDER BY md.keyword_count DESC, m.production_year) AS keyword_rank
FROM 
    RankedMovies m
LEFT JOIN 
    MovieDetails md ON m.movie_id = md.movie_id
WHERE 
    md.keyword_count > 0 OR m.title LIKE '%Game%'
ORDER BY 
    COALESCE(m.production_year, -1) DESC, 
    md.keyword_count DESC,
    m.title;

This query performs a robust analysis of movies by utilizing:
- Common Table Expressions (CTEs) to logically segment processing into manageable parts (RankedMovies and MovieDetails).
- Window functions to rank the movies and associated keywords by year and keyword count.
- Outer joins to include aspects of the data that may be missing (e.g., cast names and keywords).
- String aggregation to compile lists of cast names and keywords associated with each movie.
- COALESCE and complex predicate logic to handle NULLs and provide alternate display text.
- A consideration for corner cases, such as movies with zero keywords that might contain the term "Game" in their title.

The resultant dataset is ordered in a way that prioritizes higher keyword counts and production years, along with accommodating potential NULL values.
