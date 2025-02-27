WITH ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS actor_role,
        COUNT(c.movie_id) AS total_movies
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.name, t.title, t.production_year, r.role
),
KeywordMovies AS (
    SELECT 
        t.title AS movie_title,
        k.keyword AS movie_keyword,
        t.production_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MostPopularActors AS (
    SELECT 
        actor_name,
        SUM(total_movies) AS total_movies_played
    FROM 
        ActorMovies
    GROUP BY 
        actor_name
    ORDER BY 
        total_movies_played DESC
    LIMIT 10
)
SELECT 
    m.actor_name,
    COALESCE(mk.movie_keyword, 'No keywords found') AS movie_keyword,
    m.total_movies AS total_movies_played
FROM 
    MostPopularActors m
LEFT JOIN 
    KeywordMovies mk ON m.actor_name IN (SELECT a.name FROM aka_name a JOIN cast_info c ON a.person_id = c.person_id JOIN aka_title t ON c.movie_id = t.movie_id WHERE t.title = mk.movie_title)
ORDER BY 
    m.total_movies_played DESC;
