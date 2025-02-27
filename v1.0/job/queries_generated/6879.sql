WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        a.person_id
    FROM 
        aka_name a 
    WHERE 
        a.name IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id, 
        c.person_id, 
        c.role_id, 
        r.role AS role_name
    FROM 
        cast_info c 
    JOIN 
        role_type r ON c.role_id = r.id
)
SELECT 
    rm.movie_title, 
    rm.production_year, 
    ad.actor_name, 
    cd.role_name
FROM 
    RankedMovies rm
JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
JOIN 
    ActorDetails ad ON cd.person_id = ad.person_id
WHERE 
    rm.rank <= 5 
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title;
