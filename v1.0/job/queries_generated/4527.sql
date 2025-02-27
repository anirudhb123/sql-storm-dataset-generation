WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
),
ActorStats AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT production_year) AS year_count,
        COUNT(*) AS total_movies,
        AVG(actor_rank) AS avg_actor_rank
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
),
TopActors AS (
    SELECT 
        actor_name,
        total_movies,
        RANK() OVER (ORDER BY total_movies DESC) AS rank
    FROM 
        ActorStats
    WHERE 
        year_count > 5
)
SELECT 
    ta.actor_name,
    ta.total_movies,
    COALESCE(ta.rank, 'No Rank') AS rank,
    STRING_AGG(DISTINCT mt.title, ', ') AS movies
FROM 
    TopActors ta
LEFT JOIN 
    RankedMovies mt ON ta.actor_name = mt.actor_name
WHERE 
    ta.total_movies > 10
GROUP BY 
    ta.actor_name, ta.total_movies, ta.rank
ORDER BY 
    ta.total_movies DESC;
