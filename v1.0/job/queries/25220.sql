WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        k.keyword AS genre_keyword
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND a.name IS NOT NULL
),
aggregated_data AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(DISTINCT actor_name) AS actor_count,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors_list,
        STRING_AGG(DISTINCT genre_keyword, ', ') AS genre_keywords
    FROM 
        movie_data
    GROUP BY 
        movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    actor_count,
    actors_list,
    genre_keywords
FROM 
    aggregated_data
ORDER BY 
    production_year DESC,
    actor_count DESC;
