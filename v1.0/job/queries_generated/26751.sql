WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),

TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(actor_name, ', ') AS actors
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 3
    GROUP BY 
        movie_title, production_year
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.actors,
    COUNT(mk.keyword) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON mk.movie_id IN (
        SELECT id FROM aka_title WHERE title = tm.movie_title AND production_year = tm.production_year
    )
GROUP BY 
    tm.movie_title, tm.production_year, tm.actors
ORDER BY 
    tm.production_year DESC, 
    keyword_count DESC;

This query does the following:
1. It creates a Common Table Expression (CTE) `RankedMovies` to rank actors in movies produced between the years 2000 and 2020.
2. It then selects top movies and actors from that CTE, gathering the top three actors for each movie.
3. Finally, it counts the number of associated keywords for each movie while grouping by the movie title, production year, and actors, providing an ordered list of movies based on their production year and keyword count.
