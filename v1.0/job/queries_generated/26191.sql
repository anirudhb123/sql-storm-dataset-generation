WITH ActorMovieCounts AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
),
MostProlificActors AS (
    SELECT 
        actor_name
    FROM 
        ActorMovieCounts
    WHERE 
        movie_count >= (SELECT AVG(movie_count) FROM ActorMovieCounts)
),
TopMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(mc.company_id) AS company_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        company_count DESC
    LIMIT 10
),
ActorInTopMovies AS (
    SELECT 
        a.name AS actor_name,
        tm.title AS movie_title,
        tm.production_year
    FROM 
        MostProlificActors ma
    JOIN 
        cast_info ci ON ma.actor_name = (SELECT name FROM aka_name WHERE person_id = ci.person_id)
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        TopMovies tm ON t.title = tm.title
)
SELECT 
    actor_name,
    movie_title,
    production_year
FROM 
    ActorInTopMovies
ORDER BY 
    production_year DESC, actor_name;

This SQL query accomplishes several tasks that involve string processing, including identifying prolific actors and their participation in top movies, sorted by production year. The query employs common table expressions (CTEs) for clarity and modularity in handling data operations.
