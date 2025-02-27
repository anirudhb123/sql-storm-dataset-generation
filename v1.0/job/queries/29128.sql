
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.id AS movie_id,
        r.role AS role_name,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
ActorCounts AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(actor_name) AS actor_count
    FROM 
        RankedMovies
    GROUP BY 
        movie_title, production_year
),
HighActorCountMovies AS (
    SELECT 
        movie_title,
        production_year
    FROM 
        ActorCounts
    WHERE 
        actor_count > 5
)
SELECT 
    ha.movie_title,
    ha.production_year,
    STRING_AGG(ra.actor_name ORDER BY ra.actor_rank) AS actors_list
FROM 
    HighActorCountMovies ha
JOIN 
    RankedMovies ra ON ha.movie_title = ra.movie_title AND ha.production_year = ra.production_year
GROUP BY 
    ha.movie_title, ha.production_year
ORDER BY 
    ha.production_year DESC, ha.movie_title;
