WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS year,
        COUNT(c.id) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name, t.title, t.production_year
),
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        SUM(role_count) AS total_roles
    FROM 
        ActorMovies
    GROUP BY 
        actor_id, actor_name
    ORDER BY 
        total_roles DESC
    LIMIT 10
)
SELECT 
    ta.actor_id,
    ta.actor_name,
    am.movie_title,
    am.year,
    am.role_count
FROM 
    TopActors ta
JOIN 
    ActorMovies am ON ta.actor_id = am.actor_id
ORDER BY 
    ta.total_roles DESC, am.year DESC;