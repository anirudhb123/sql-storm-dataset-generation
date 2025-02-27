WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) OVER (PARTITION BY c.movie_id, r.role ORDER BY c.nr_order) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
)
SELECT 
    tm.title,
    tm.production_year,
    ar.actor_name,
    ar.role_name,
    ar.role_count
FROM 
    TopMovies tm
LEFT JOIN 
    ActorRoles ar ON tm.movie_id = ar.movie_id
WHERE 
    (ar.role_name IS NULL OR ar.role_count > 1)
ORDER BY 
    tm.production_year DESC, 
    ar.role_count DESC NULLS LAST;
