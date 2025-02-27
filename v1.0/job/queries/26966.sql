
WITH NameCounts AS (
    SELECT 
        n.id AS name_id,
        n.name AS actor_name,
        COUNT(c.id) AS movie_count
    FROM 
        name n
    JOIN 
        cast_info c ON n.id = c.person_id
    GROUP BY 
        n.id, n.name
),
TopActors AS (
    SELECT 
        actor_name, 
        movie_count 
    FROM 
        NameCounts 
    WHERE 
        movie_count > 5
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        n.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        name n ON ci.person_id = n.id
    JOIN 
        TopActors a ON n.name = a.actor_name
)
SELECT 
    md.movie_title,
    md.production_year,
    COUNT(*) AS actor_appearances,
    STRING_AGG(DISTINCT md.actor_name, ', ') AS co_actors
FROM 
    MovieDetails md
GROUP BY 
    md.movie_title, 
    md.production_year
ORDER BY 
    actor_appearances DESC, 
    md.production_year DESC;
