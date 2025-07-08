
WITH RECURSIVE ActorMovies AS (
    SELECT 
        ca.person_id, 
        at.title AS movie_title, 
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY at.production_year DESC) AS movie_rank
    FROM 
        cast_info ca
    JOIN 
        aka_title at ON ca.movie_id = at.id
    WHERE 
        at.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        person_id, 
        COUNT(*) AS total_movies
    FROM 
        ActorMovies
    WHERE 
        movie_rank <= 3  
    GROUP BY 
        person_id
    ORDER BY 
        total_movies DESC
    LIMIT 10
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name, 
        ta.total_movies,
        LISTAGG(am.movie_title || ' (' || am.production_year || ')', ', ') WITHIN GROUP (ORDER BY am.production_year DESC) AS recent_movies
    FROM 
        TopActors ta
    JOIN 
        aka_name ak ON ta.person_id = ak.person_id
    JOIN 
        ActorMovies am ON ta.person_id = am.person_id
    GROUP BY 
        ak.name, ta.total_movies
)
SELECT 
    ad.actor_name, 
    ad.total_movies,
    COALESCE(ad.recent_movies, 'No movies found') AS recent_movies
FROM 
    ActorDetails ad
LEFT JOIN 
    role_type rt ON ad.total_movies > 5 AND rt.role = 'Leading'
WHERE 
    ad.total_movies IS NOT NULL
ORDER BY 
    ad.total_movies DESC;
