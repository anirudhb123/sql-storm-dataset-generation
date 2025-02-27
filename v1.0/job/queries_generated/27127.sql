WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
),
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        production_year,
        movie_rank
    FROM 
        ActorMovies
    WHERE 
        movie_rank <= 5
),
AlternateNames AS (
    SELECT 
        cn.id AS alternate_id,
        cn.name AS alternate_name,
        a.actor_id,
        a.actor_name
    FROM 
        char_name cn
    JOIN 
        aka_name a ON a.md5sum = cn.md5sum
)
SELECT 
    ta.actor_id,
    ta.actor_name,
    ta.movie_title,
    ta.production_year,
    an.alternate_id,
    an.alternate_name
FROM 
    TopActors ta
LEFT JOIN 
    AlternateNames an ON ta.actor_id = an.actor_id
ORDER BY 
    ta.actor_name, ta.production_year DESC;

This query benchmarks string processing by firstly aggregating information about actors and the movies they've acted in, limited to the top 5 most recent movies per actor. It then joins this information with alternative names for those actors. The final selection orders the results by actor name and movie production year, showcasing a variety of string manipulations and joins.
