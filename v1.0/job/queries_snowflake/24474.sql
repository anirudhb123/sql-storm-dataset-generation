
WITH RecursiveActorMovies AS (
    SELECT
        a.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        COALESCE(t.production_year, 0) AS production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        a.name IS NOT NULL AND
        t.production_year IS NOT NULL
),
MoviesPerYear AS (
    SELECT
        production_year,
        COUNT(movie_title) AS total_movies,
        SUM(CASE WHEN actor_name IS NOT NULL THEN 1 ELSE 0 END) AS active_actors
    FROM 
        RecursiveActorMovies
    GROUP BY 
        production_year
),
TopMovies AS (
    SELECT 
        mp.production_year,
        mp.total_movies,
        mp.active_actors,
        ROW_NUMBER() OVER (ORDER BY mp.total_movies DESC) AS rank
    FROM 
        MoviesPerYear mp
)
SELECT 
    t.production_year,
    t.total_movies,
    COALESCE(t.active_actors, 0) AS active_actors,
    LISTAGG(a.actor_name, ', ') WITHIN GROUP (ORDER BY a.actor_name) AS actor_names,
    CASE 
        WHEN t.active_actors IS NULL THEN 'No actors found' 
        ELSE 'Actors present' 
    END AS actor_presence_status
FROM 
    TopMovies t
LEFT JOIN 
    RecursiveActorMovies a ON a.production_year = t.production_year
WHERE 
    t.rank <= 10
GROUP BY 
    t.production_year, t.total_movies, t.active_actors
UNION ALL
SELECT 
    NULL AS production_year,
    SUM(mp.total_movies) AS total_movies,
    SUM(mp.active_actors) AS active_actors,
    NULL AS actor_names,
    'Overall Status' AS actor_presence_status
FROM 
    MoviesPerYear mp
WHERE 
    mp.total_movies > 0
ORDER BY 
    production_year DESC NULLS LAST;
