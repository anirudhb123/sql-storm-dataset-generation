WITH movie_actor_info AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS role_description
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
        AND a.name ILIKE '%John%'
),
movie_keywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id
),
actor_movie_info AS (
    SELECT 
        mai.actor_name,
        mai.movie_title,
        mai.production_year,
        mai.role_description,
        mk.keywords
    FROM 
        movie_actor_info mai
    LEFT JOIN 
        movie_keywords mk ON mai.movie_title = mk.movie_title
)
SELECT 
    actor_name, 
    movie_title,
    production_year, 
    role_description, 
    keywords
FROM 
    actor_movie_info
WHERE 
    keywords IS NOT NULL 
ORDER BY 
    production_year DESC, 
    actor_name;
