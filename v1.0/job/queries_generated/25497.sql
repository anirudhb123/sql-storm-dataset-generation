WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        actor_count,
        RANK() OVER (PARTITION BY keyword ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    tm.actor_count
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.keyword, 
    tm.actor_count DESC;

This SQL query benchmarks string processing by performing the following tasks:

1. **Rank Movies**: It first creates a common table expression (`RankedMovies`) that joins `aka_title`, `movie_keyword`, and `keyword` tables to count the number of distinct actors (`person_id`) for each movie, grouped by movie title, production year, and keywords. It filters movies that were produced after the year 2000.

2. **Top Movies**: Another CTE (`TopMovies`) ranks the movies based on the number of actors for each keyword.

3. **Final Selection**: Finally, it selects the top 10 movies per keyword based on actor count and orders the results by keyword and descending actor count, producing a comprehensive benchmarking output.
