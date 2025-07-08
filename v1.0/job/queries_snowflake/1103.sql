WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        COUNT(ci.person_role_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, a.name, rt.role
),
MoviesWithActorCounts AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        COALESCE(SUM(ar.role_count), 0) AS total_actors
    FROM 
        RankedTitles r
    LEFT JOIN 
        ActorRoles ar ON r.title_id = ar.movie_id
    GROUP BY 
        r.title_id, r.title, r.production_year
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        total_actors,
        RANK() OVER (ORDER BY total_actors DESC) AS actor_rank
    FROM 
        MoviesWithActorCounts
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_actors,
    a.name AS top_actor,
    ar.role_name
FROM 
    TopMovies tm
LEFT JOIN 
    ActorRoles ar ON tm.title_id = ar.movie_id
LEFT JOIN 
    (SELECT 
        movie_id,
        name,
        RANK() OVER (PARTITION BY movie_id ORDER BY COUNT(person_role_id) DESC) AS actor_rank
     FROM 
        cast_info ci
     JOIN 
        aka_name a ON ci.person_id = a.person_id
     GROUP BY 
        movie_id, a.name) a ON ar.movie_id = a.movie_id AND a.actor_rank = 1
WHERE 
    tm.actor_rank <= 10
ORDER BY 
    tm.total_actors DESC, tm.production_year DESC;
