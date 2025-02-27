WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT a.name ORDER BY a.name) AS cast_names,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t 
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id 
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        cast_names,
        movie_keyword,
        rank_by_cast
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names,
    ARRAY_AGG(DISTINCT mt.info) AS movie_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
GROUP BY 
    tm.title, tm.production_year, tm.cast_count, tm.cast_names
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;

### Explanation:
- This query retrieves the top 5 movies, ranked by cast count, for each production year from the content of the `aka_title`, `cast_info`, `aka_name`, `movie_keyword`, and `keyword` tables.
- It uses **Common Table Expressions (CTEs)** to first rank the movies based on the number of unique cast members.
- The main query then aggregates additional information, including movie info linked to these top movies, and orders the results by production year and cast count. 
- The result includes the movie title, production year, number of distinct cast members, their names (as an array), and an array of movie-related information.
