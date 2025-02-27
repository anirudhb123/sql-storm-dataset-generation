WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_rank
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id 
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.title, t.production_year, a.name
),
ActorMovieCount AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT production_year) AS year_count,
        COUNT(DISTINCT title) AS movie_count
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
),
TopActors AS (
    SELECT 
        actor_name,
        movie_count,
        year_count,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        ActorMovieCount
)

SELECT 
    ta.actor_name,
    ta.movie_count AS total_movies,
    ta.year_count AS unique_years,
    RANK() OVER (ORDER BY ta.year_count DESC) AS year_rank
FROM 
    TopActors ta
WHERE 
    ta.rank <= 10
ORDER BY 
    ta.movie_count DESC;

This query creates several Common Table Expressions (CTEs) to first rank movies based on the number of actors appearing in them per production year. It then counts how many unique production years each actor has been in movies and how many movies each actor has appeared in. Finally, it ranks actors based on their movie count and retrieves the top 10 actors along with their movie count and unique production years.
