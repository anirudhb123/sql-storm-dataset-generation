WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_year
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        c.nr_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
)
SELECT 
    rm.title,
    rm.production_year,
    ad.actor_name,
    ad.nr_order
FROM 
    RankedMovies rm
JOIN 
    ActorDetails ad ON rm.movie_id = ad.movie_id
WHERE 
    rm.rank_year <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title, 
    ad.nr_order;
