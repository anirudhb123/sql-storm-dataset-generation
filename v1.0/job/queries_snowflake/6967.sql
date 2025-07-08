WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn
    FROM title m
    WHERE m.production_year IS NOT NULL
), ActorRoles AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id, a.name, r.role
), DetailedMovieInfo AS (
    SELECT 
        mv.movie_id,
        mv.title,
        mv.production_year,
        ac.actor_name,
        ac.role_name,
        ac.role_count
    FROM RankedMovies mv
    JOIN ActorRoles ac ON mv.movie_id = ac.movie_id
)
SELECT 
    d.movie_id,
    d.title,
    d.production_year,
    d.actor_name,
    d.role_name,
    d.role_count
FROM DetailedMovieInfo d
WHERE d.role_count > 1
ORDER BY d.production_year DESC, d.title;
