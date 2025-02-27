WITH movie_actors AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ct.kind AS role_type
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        role_type ct ON ci.role_id = ct.id
),
keyword_movies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        ma.actor_name,
        ma.movie_title,
        ma.production_year,
        ma.role_type,
        km.keywords
    FROM 
        movie_actors ma
    LEFT JOIN 
        keyword_movies km ON ma.movie_title = (SELECT title FROM aka_title WHERE movie_id = km.movie_id LIMIT 1)
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    role_type,
    keywords
FROM 
    movie_details
WHERE 
    production_year > 2000
ORDER BY 
    production_year DESC, 
    actor_name;
