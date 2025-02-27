WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        cast_count, 
        aka_names, 
        keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id, 
    tm.movie_title, 
    tm.production_year, 
    tm.cast_count, 
    tm.aka_names, 
    tm.keywords 
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC;

This query benchmarks string processing by aggregating actor names and keywords for movies and including them in a ranked list. The `STRING_AGG` function is used to concatenate the names and keywords into a single string for easier readability, while the `ROW_NUMBER` function ranks the movies based on their cast count, giving us the top 10 movies with the most cast members and their associated AKA names and keywords.
