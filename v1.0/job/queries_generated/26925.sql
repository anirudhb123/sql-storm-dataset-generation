WITH ActorMovieCounts AS (
    SELECT 
        ak.person_id, 
        COUNT(DISTINCT ca.movie_id) AS movie_count 
    FROM 
        aka_name ak
    JOIN 
        cast_info ca ON ak.person_id = ca.person_id 
    GROUP BY 
        ak.person_id
),
TopActors AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        ac.movie_count
    FROM 
        aka_name ak
    JOIN 
        ActorMovieCounts ac ON ak.person_id = ac.person_id
    ORDER BY 
        ac.movie_count DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT 
        mv.id AS movie_id,
        mv.title AS movie_title,
        mv.production_year,
        k.keyword AS keyword
    FROM 
        aka_title mv
    JOIN 
        movie_keyword mk ON mv.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)

SELECT 
    ta.actor_name,
    COUNT(DISTINCT md.movie_id) AS total_movies,
    STRING_AGG(DISTINCT md.movie_title || ' (' || md.production_year || ')' || ' - ' || md.keyword, ', ') AS movie_info
FROM 
    TopActors ta
LEFT JOIN 
    cast_info ci ON ta.actor_id = ci.person_id
LEFT JOIN 
    MovieDetails md ON ci.movie_id = md.movie_id
GROUP BY 
    ta.actor_name
ORDER BY 
    total_movies DESC;
