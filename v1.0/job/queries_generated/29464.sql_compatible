
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
TopActors AS (
    SELECT 
        actor_name 
    FROM 
        ActorMovieCount 
    WHERE 
        movie_count > 5
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IN (SELECT actor_name FROM TopActors)
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        MovieDetails m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.title,
    md.production_year,
    kc.keyword_count,
    (SELECT COUNT(*) FROM MovieDetails) AS total_movies
FROM 
    MovieDetails md
JOIN 
    KeywordCounts kc ON md.movie_id = kc.movie_id
ORDER BY 
    kc.keyword_count DESC, 
    md.production_year DESC;
