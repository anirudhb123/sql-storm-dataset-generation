WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),
GenreMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        kt.kind AS genre,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, kt.kind
),
TopMovies AS (
    SELECT 
        gm.movie_id,
        gm.title,
        gm.genre,
        gm.actor_count,
        ROW_NUMBER() OVER (PARTITION BY gm.genre ORDER BY gm.actor_count DESC) AS genre_rank
    FROM 
        GenreMovies gm
)
SELECT 
    am.actor_id,
    am.actor_name,
    tm.title AS top_movie,
    tm.genre,
    tm.actor_count
FROM 
    ActorMovies am
JOIN 
    TopMovies tm ON am.movie_count < 5 AND tm.genre_rank <= 5
WHERE 
    am.movie_count > 10
ORDER BY 
    am.actor_name, tm.genre;

This SQL query retrieves a list of actors who have acted in more than 10 movies, along with their names, the titles of the top 5 movies (based on actor counts) from each genre they acted in. It uses Common Table Expressions (CTEs) to first get the count of movies each actor has appeared in, the count of actors for each movie by genre, and finally to rank those movies by the number of actors in each genre. The final selection pulls from these rankings and filters to include only actors with fewer than 5 top movies, allowing for an interesting exploration of actor collaborations across various genres.
