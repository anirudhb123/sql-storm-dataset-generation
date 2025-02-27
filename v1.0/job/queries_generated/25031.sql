WITH ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS role_name,
        COUNT(*) AS title_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL AND 
        t.production_year > 2000
    GROUP BY 
        a.name, t.title, t.production_year, r.role
), 
MostProlificActors AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        ActorMovies
    GROUP BY 
        actor_name
    HAVING 
        movie_count > 5
), 
ActorDetails AS (
    SELECT 
        ma.actor_name,
        ma.movie_title,
        ma.production_year,
        ma.role_name,
        mb.info AS actor_info
    FROM 
        ActorMovies ma
    LEFT JOIN 
        person_info mb ON (SELECT person_id FROM aka_name WHERE name = ma.actor_name LIMIT 1) = mb.person_id
    WHERE 
        ma.actor_name IN (SELECT actor_name FROM MostProlificActors)
)
SELECT 
    ad.actor_name,
    ad.movie_title,
    ad.production_year,
    ad.role_name,
    ad.actor_info
FROM 
    ActorDetails ad
ORDER BY 
    ad.actor_name, ad.production_year DESC;
