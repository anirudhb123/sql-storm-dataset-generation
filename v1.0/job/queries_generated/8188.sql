WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        ka.name AS actor_name,
        cc.movie_id,
        c.role_id
    FROM 
        cast_info cc
    JOIN 
        aka_name ka ON cc.person_id = ka.person_id
    JOIN 
        role_type c ON cc.role_id = c.id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    ad.actor_name,
    ad.role_id
FROM 
    RankedMovies rm
JOIN 
    ActorDetails ad ON rm.movie_id = ad.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title ASC;
