WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year, 
        r.role AS role_name
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name ILIKE '%Smith%' AND 
        t.production_year BETWEEN 2000 AND 2023
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        k.keyword
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
)

SELECT 
    am.actor_name,
    COUNT(DISTINCT am.movie_title) AS movie_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT am.role_name, ', ') AS roles
FROM 
    ActorMovies am
LEFT JOIN 
    MovieKeywords mk ON am.movie_title = mk.movie_id
GROUP BY 
    am.actor_name
ORDER BY 
    movie_count DESC
LIMIT 10;
