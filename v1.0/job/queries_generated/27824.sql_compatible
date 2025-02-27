
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, a.name, r.role
), 
actor_movie_count AS (
    SELECT 
        actor_name, 
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        movie_details
    GROUP BY 
        actor_name
), 
top_actors AS (
    SELECT 
        actor_name, 
        movie_count,
        ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS ranking
    FROM 
        actor_movie_count
)
SELECT 
    md.movie_title,
    md.production_year,
    ta.actor_name,
    ta.movie_count,
    ta.ranking
FROM 
    movie_details md
JOIN 
    top_actors ta ON md.actor_name = ta.actor_name
WHERE 
    ta.ranking <= 10
ORDER BY 
    ta.ranking, md.production_year DESC;
