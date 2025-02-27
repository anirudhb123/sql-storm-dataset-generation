WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at 
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        at.id, at.title, at.production_year, ak.name
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_name 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
)

SELECT 
    tm.production_year,
    STRING_AGG(tm.actor_name, ', ') AS actors,
    COUNT(DISTINCT tm.movie_id) AS total_movies
FROM 
    TopMovies tm
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year DESC;

This query ranks movies based on their year of production and the number of actors in each film, then retrieves the top 5 movies for each year along with the actors involved and the total count of unique movies for each production year. The results are aggregated to provide a clear insight into the distribution of actors per year, showcasing how string processing functions like `STRING_AGG` can combine multiple actor names efficiently.
