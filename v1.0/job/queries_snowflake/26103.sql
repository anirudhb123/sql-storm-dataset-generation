
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
    LISTAGG(tm.actor_name, ', ') WITHIN GROUP (ORDER BY tm.actor_name) AS actors,
    COUNT(DISTINCT tm.movie_id) AS total_movies
FROM 
    TopMovies tm
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year DESC;
