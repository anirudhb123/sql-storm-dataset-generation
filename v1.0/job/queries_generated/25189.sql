WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mt.id, mt.title, ak.name, mt.production_year
), 
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    STRING_AGG(tm.actor_name, ', ') AS top_actors,
    tm.cast_count
FROM 
    TopMovies tm
GROUP BY 
    tm.movie_title, tm.production_year
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
