
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT a.name) AS actor_names
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        actor_count, 
        actor_names,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id, 
    tm.title, 
    tm.production_year, 
    tm.actor_count, 
    tm.actor_names
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.actor_count DESC;
