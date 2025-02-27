WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    JOIN 
        name a ON ak.person_id = a.imdb_id
    WHERE 
        a.gender = 'm' AND
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
FilteredMovies AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 3
)
SELECT 
    f.actor_id,
    f.actor_name,
    STRING_AGG(f.movie_title || ' (' || f.production_year || ')', ', ') AS movies
FROM 
    FilteredMovies f
GROUP BY 
    f.actor_id, f.actor_name
ORDER BY 
    f.actor_name;
