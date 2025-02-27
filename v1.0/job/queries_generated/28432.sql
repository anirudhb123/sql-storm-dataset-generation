WITH MovieActorRoles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS role_name,
        COUNT(DISTINCT m.id) AS total_movies,
        STRING_AGG(DISTINCT t.title, ', ') AS all_movies
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.id, t.id, r.role
),

TopActors AS (
    SELECT 
        actor_name,
        SUM(total_movies) AS total_movies_played,
        STRING_AGG(movie_title, ', ') AS unique_movies
    FROM 
        MovieActorRoles
    GROUP BY 
        actor_name
    HAVING 
        SUM(total_movies) > 1  -- We are interested in actors who've played in multiple roles
    ORDER BY 
        total_movies_played DESC
    LIMIT 10
),

ActorMovieInfo AS (
    SELECT 
        ta.actor_name,
        tm.title,
        tm.production_year,
        GROUP_CONCAT(DISTINCT ki.keyword ORDER BY ki.keyword) AS keywords
    FROM 
        TopActors ta
    JOIN 
        movie_keyword mk ON tk.id = mk.movie_id
    JOIN 
        keyword ki ON mk.keyword_id = ki.id
    JOIN 
        title tm ON mk.movie_id = tm.id
    GROUP BY 
        ta.actor_name, tm.title, tm.production_year
)

SELECT 
    ami.actor_name,
    ami.title,
    ami.production_year,
    ami.keywords
FROM 
    ActorMovieInfo ami
ORDER BY 
    ami.actor_name, ami.production_year;

This SQL query benchmarks string processing by extracting information about the top actors based on the number of roles played in various movies. It aggregates movie titles, roles, and keywords associated with the films, with the result ordered by actor names and production years, allowing for comprehensive analysis of string data across multiple dimensions.
