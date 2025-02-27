WITH genre_info AS (
    SELECT 
        k.keyword AS genre,
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
        AND k.keyword IS NOT NULL
    GROUP BY 
        genre, movie_title, t.production_year, actor_name
), actor_stats AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS total_movies,
        AVG(production_year) AS average_year
    FROM 
        genre_info
    GROUP BY 
        actor_name
)
SELECT 
    ag.actor_name,
    ag.total_movies,
    ag.average_year,
    COUNT(DISTINCT g.genre) AS genre_count
FROM 
    actor_stats ag
JOIN 
    genre_info g ON ag.actor_name = g.actor_name
GROUP BY 
    ag.actor_name, ag.total_movies, ag.average_year
ORDER BY 
    total_movies DESC, average_year DESC
LIMIT 10;
