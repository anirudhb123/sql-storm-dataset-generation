WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.keyword,
    tm.cast_count
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.production_year, tm.rank;

The above SQL query does the following:

1. **Common Table Expression (CTE)**: `RankedMovies` computes a list of movies from the `aka_title` table, joining with the keyword and cast information. It counts the number of cast entries for each movie, grouping by movie details and keyword.

2. **Ranking**: The CTE `TopMovies` ranks these movies within each production year based on the number of cast members (`cast_count`), allowing us to find the top 5 movies for each year.

3. **Final Selection**: The final `SELECT` picks the top 5 movies from each year, displaying their ID, title, production year, associated keyword (with a fallback if none is available), and cast count, ordered first by production year and then by rank.
