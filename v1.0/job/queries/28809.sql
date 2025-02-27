
WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        a.name AS actor_name,
        a.imdb_index AS actor_imdb_index,
        pt.role AS person_role
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type pt ON ci.role_id = pt.id
    WHERE 
        m.production_year >= 2000 AND 
        m.kind_id IN (1, 2) 
),
actor_summary AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS total_movies,
        STRING_AGG(DISTINCT movie_title, ', ') AS movies_list,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        movie_details
    GROUP BY 
        actor_name
)
SELECT 
    actor_name,
    total_movies,
    movies_list,
    keywords
FROM 
    actor_summary
WHERE 
    total_movies > 5
ORDER BY 
    total_movies DESC;
