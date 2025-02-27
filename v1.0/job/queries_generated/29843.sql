WITH RankedActors AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a 
    JOIN 
        cast_info ci ON a.person_id = ci.person_id 
    GROUP BY 
        a.id, a.name 
    HAVING 
        COUNT(ci.movie_id) > 10
), TopMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        ARRAY_AGG(DISTINCT g.kind) AS genres
    FROM 
        aka_title t 
    JOIN 
        kind_type g ON t.kind_id = g.id 
    GROUP BY 
        t.id, t.title, t.production_year 
    ORDER BY 
        t.production_year DESC 
    LIMIT 100
), ActorMovieDetails AS (
    SELECT 
        ra.actor_name,
        tm.movie_title,
        tm.production_year,
        tm.genres,
        c.role_id,
        r.role AS role_name
    FROM 
        RankedActors ra 
    JOIN 
        cast_info c ON ra.actor_id = c.person_id 
    JOIN 
        TopMovies tm ON c.movie_id = tm.movie_id 
    JOIN 
        role_type r ON c.role_id = r.id 
)
SELECT 
    amd.actor_name,
    amd.movie_title,
    amd.production_year,
    STRING_AGG(DISTINCT unnest(amd.genres), ', ') AS genre_list,
    COUNT(*) OVER (PARTITION BY amd.actor_name) AS total_movies
FROM 
    ActorMovieDetails amd
GROUP BY 
    amd.actor_name, amd.movie_title, amd.production_year
ORDER BY 
    total_movies DESC, amd.actor_name, amd.production_year;
