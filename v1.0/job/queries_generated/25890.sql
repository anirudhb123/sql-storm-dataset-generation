WITH ActorMovieCounts AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
PopularMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 10
),
ActorStats AS (
    SELECT 
        am.actor_name,
        COUNT(pm.movie_title) AS popular_movie_count,
        SUM(pm.actor_count) AS total_actor_count_in_popular_movies
    FROM 
        ActorMovieCounts am
    LEFT JOIN 
        PopularMovies pm ON am.movie_count > 5
    GROUP BY 
        am.actor_name
    ORDER BY 
        popular_movie_count DESC
)
SELECT 
    actor_name, 
    popular_movie_count,
    total_actor_count_in_popular_movies
FROM 
    ActorStats
WHERE 
    popular_movie_count > 0
LIMIT 10;
