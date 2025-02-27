WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY rc.nr_order) AS actor_rank
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info rc ON cc.id = rc.id
    JOIN 
        aka_name cn ON rc.person_id = cn.person_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
TopActors AS (
    SELECT 
        movie_title,
        production_year,
        actor_name
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 3
)
SELECT 
    r.movie_title,
    r.production_year,
    STRING_AGG(r.actor_name, ', ') AS top_actors
FROM 
    TopActors r
GROUP BY 
    r.movie_title, r.production_year
ORDER BY 
    r.production_year DESC, r.movie_title;
