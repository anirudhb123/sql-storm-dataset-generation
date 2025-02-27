
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title,
        production_year,
        actor_count,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rn,
        actor_names
    FROM 
        MovieDetails
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.actor_count,
    tm.actor_names
FROM 
    TopMovies tm
WHERE 
    tm.actor_count > (
        SELECT AVG(actor_count) FROM TopMovies
    )
ORDER BY 
    tm.actor_count DESC
LIMIT 10;
