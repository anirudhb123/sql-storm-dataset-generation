WITH movie_actor_info AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.nr_order,
        r.role AS actor_role,
        k.keyword AS movie_keyword
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
        AND a.name IS NOT NULL
        AND t.title IS NOT NULL
),
actor_summary AS (
    SELECT 
        actor_name,
        COUNT(*) AS movies_count,
        STRING_AGG(DISTINCT movie_title, ', ') AS movies_list,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords_list,
        AVG(production_year) AS average_production_year
    FROM 
        movie_actor_info
    GROUP BY 
        actor_name
)
SELECT 
    actor_name,
    movies_count,
    movies_list,
    keywords_list,
    average_production_year
FROM 
    actor_summary
WHERE 
    movies_count > 5
ORDER BY 
    average_production_year DESC;
