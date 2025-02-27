WITH MovieTitles AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year
    FROM 
        MovieTitles mt
    WHERE 
        mt.title_rank <= 10
),
ActorRoles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role AS role_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id, c.movie_id, r.role
),
ActorMovieStats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT a.movie_id) AS total_movies,
        SUM(CASE WHEN r.role_name IS NOT NULL THEN 1 ELSE 0 END) AS acting_roles
    FROM 
        ActorRoles r
    JOIN 
        aka_name a ON r.person_id = a.person_id
    GROUP BY 
        a.person_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    am.total_movies,
    am.acting_roles
FROM 
    TopMovies m
JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    ActorMovieStats am ON am.person_id = a.person_id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC, a.name;
