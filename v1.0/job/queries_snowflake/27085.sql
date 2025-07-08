WITH RankedActors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS total_movies,
        RANK() OVER (ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),
TopGenres AS (
    SELECT 
        k.keyword AS genre,
        COUNT(mk.movie_id) AS genre_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        k.keyword
    ORDER BY 
        genre_count DESC
    LIMIT 10
),
TopMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(ci.person_id) > 10
    ORDER BY 
        actor_count DESC
    LIMIT 5
)
SELECT 
    ra.actor_id,
    ra.actor_name,
    ra.total_movies,
    tg.genre AS popular_genre,
    tm.movie_title,
    tm.production_year
FROM 
    RankedActors ra
CROSS JOIN 
    TopGenres tg
JOIN 
    TopMovies tm ON ra.total_movies > 3
WHERE 
    ra.actor_rank <= 20
ORDER BY 
    ra.total_movies DESC, tg.genre DESC;
