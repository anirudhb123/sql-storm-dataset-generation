WITH ActorMovies AS (
    SELECT 
        ka.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ka.id AS actor_id,
        COUNT(DISTINCT cc.movie_id) AS co_actor_count
    FROM 
        aka_name ka
    JOIN 
        cast_info cc ON ka.person_id = cc.person_id
    JOIN 
        aka_title at ON cc.movie_id = at.movie_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        ka.name, at.title, at.production_year, ka.id
), 

CoActors AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        COUNT(DISTINCT ca.person_id) AS unique_co_actors
    FROM 
        ActorMovies am
    JOIN 
        cast_info cc ON am.actor_id = cc.person_id
    JOIN 
        cast_info ca ON cc.movie_id = ca.movie_id AND ca.person_id != am.actor_id
    GROUP BY 
        am.actor_name, am.movie_title, am.production_year
)

SELECT 
    actor_name,
    movie_title,
    production_year,
    unique_co_actors
FROM 
    CoActors
ORDER BY 
    production_year DESC, unique_co_actors DESC;
