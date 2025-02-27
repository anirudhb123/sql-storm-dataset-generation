WITH RECURSIVE ActorMovies AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (1, 2) 
),
MoviesWithRatings AS (
    SELECT 
        t.title,
        t.production_year,
        AVG(COALESCE(r.rating, 0)) AS average_rating
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info m ON t.movie_id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        (SELECT movie_id, CAST(info AS numeric) AS rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) r 
    ON 
        t.movie_id = r.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopActors AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS total_movies,
        AVG(average_rating) AS average_actor_rating
    FROM 
        ActorMovies am
    JOIN 
        MoviesWithRatings mr ON am.movie_title = mr.title AND am.production_year = mr.production_year
    GROUP BY 
        actor_name
    HAVING 
        COUNT(movie_title) > 3 
)
SELECT 
    ta.actor_name,
    ta.total_movies,
    ta.average_actor_rating,
    CASE 
        WHEN ta.average_actor_rating IS NULL THEN 'No ratings'
        WHEN ta.average_actor_rating >= 8.0 THEN 'Highly Rated'
        WHEN ta.average_actor_rating BETWEEN 5.0 AND 8.0 THEN 'Average Rated'
        ELSE 'Poorly Rated'
    END AS rating_category
FROM 
    TopActors ta
ORDER BY 
    ta.average_actor_rating DESC, ta.total_movies DESC;