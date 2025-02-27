WITH RecursiveActorRoles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title AS movie_title,
        rt.role AS role,
        COALESCE(NULLIF(t.production_year, 0), 'Unknown') AS production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS role_ranking
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
    JOIN role_type rt ON c.role_id = rt.id
    WHERE a.name IS NOT NULL
),
TopActorRoles AS (
    SELECT 
        actor_id,
        actor_name,
        movie_id,
        movie_title,
        role,
        production_year,
        role_ranking
    FROM RecursiveActorRoles
    WHERE role_ranking <= 5
),
ActorMovieCounts AS (
    SELECT 
        actor_id,
        COUNT(DISTINCT movie_id) AS total_movies,
        STRING_AGG(DISTINCT movie_title, ', ') AS movie_titles
    FROM TopActorRoles
    GROUP BY actor_id
),
AverageMoviesPerActor AS (
    SELECT 
        AVG(total_movies) AS avg_movies_per_actor
    FROM ActorMovieCounts
)
SELECT 
    a.actor_id,
    a.actor_name,
    a.total_movies,
    a.movie_titles,
    avg.avg_movies_per_actor
FROM ActorMovieCounts a
CROSS JOIN AverageMoviesPerActor avg
ORDER BY a.total_movies DESC
LIMIT 10;
