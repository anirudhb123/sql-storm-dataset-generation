WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn,
        COUNT(*) OVER (PARTITION BY m.production_year) AS total_movies
    FROM title m
    WHERE m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
), 
ActorMovieCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM cast_info c
    JOIN aka_name a ON a.person_id = c.person_id
    GROUP BY a.person_id
),
TopActors AS (
    SELECT 
        actor.person_id,
        a.name,
        ac.movie_count
    FROM ActorMovieCounts ac
    JOIN aka_name a ON a.person_id = ac.person_id
    WHERE ac.movie_count = (SELECT MAX(movie_count) FROM ActorMovieCounts)
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ta.name AS top_actor_name,
    ta.movie_count AS top_actor_movies,
    CASE 
        WHEN rm.rn = 1 THEN 'First Movie in Production Year'
        WHEN rm.rn = rm.total_movies THEN 'Last Movie in Production Year'
        ELSE 'Middle Movie in Production Year'
    END AS movie_position,
    NULLIF(ta.movie_count, 0) AS adjusted_movie_count
FROM RankedMovies rm
LEFT JOIN TopActors ta ON rm.movie_id IN (
    SELECT movie_id FROM cast_info WHERE person_id = ta.person_id
)
WHERE rm.production_year >= 2000 
AND rm.production_year <= EXTRACT(YEAR FROM CURRENT_DATE)
ORDER BY rm.production_year, rm.title;

This SQL query provides a detailed analysis of movies, including the ranking of movies by title within each production year, and the association of top actors who have participated in the maximum number of movies. It uses CTEs to rank the movies and count actors, employs outer joins, incorporates conditional logic, and handles potential null cases explicitly. The logic ensures that even if no actor is found for a movie, the movie data remains intact, showcasing the power of SQL in analysis and reporting.
