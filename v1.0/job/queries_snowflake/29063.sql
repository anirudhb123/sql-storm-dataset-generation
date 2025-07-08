
WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_name
    FROM 
        RankedTitles
    WHERE 
        rank <= 10
)
SELECT 
    tm.production_year,
    COUNT(tm.title) AS number_of_top_movies,
    LISTAGG(tm.actor_name, ', ') AS top_actors
FROM 
    TopMovies tm
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year DESC;
