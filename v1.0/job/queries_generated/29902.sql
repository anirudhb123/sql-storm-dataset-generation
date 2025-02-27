WITH ActorMovieCount AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name
), 
MoviesDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT a.name) AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.title, t.production_year
), 
TopActors AS (
    SELECT 
        actor_name
    FROM 
        ActorMovieCount
    WHERE 
        movie_count > 10
), 
BenchmarkResults AS (
    SELECT 
        m.movie_title,
        m.production_year,
        STRING_AGG(DISTINCT a.actor_name, ', ') AS actors,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        MoviesDetails m
    LEFT JOIN 
        movie_keyword mk ON m.movie_title = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        TopActors a ON a.actor_name = ANY(m.actor_names)
    GROUP BY 
        m.movie_title, m.production_year
)
SELECT 
    movie_title,
    production_year,
    actors,
    keyword_count
FROM 
    BenchmarkResults
ORDER BY 
    keyword_count DESC, production_year DESC
LIMIT 20;
