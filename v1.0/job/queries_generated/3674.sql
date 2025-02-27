WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        c.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ca.nr_order) AS actor_rank
    FROM 
        aka_title a
    JOIN 
        cast_info ca ON a.id = ca.movie_id
    JOIN 
        aka_name c ON ca.person_id = c.person_id
    WHERE 
        a.production_year >= 2000
),
ActorMovieCount AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
),
TopActors AS (
    SELECT 
        actor_name,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        ActorMovieCount
    WHERE 
        movie_count > 5
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    STRING_AGG(rm.movie_title, ', ') AS movies_list
FROM 
    TopActors ta
LEFT JOIN 
    RankedMovies rm ON ta.actor_name = rm.actor_name
WHERE 
    ta.rank <= 10
GROUP BY 
    ta.actor_name, ta.movie_count
ORDER BY 
    ta.movie_count DESC, ta.actor_name;
