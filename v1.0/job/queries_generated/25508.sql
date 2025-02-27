WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        a.name AS actor_name,
        ci.nr_order,
        c.kind AS cast_type
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    WHERE 
        t.production_year >= 2000
        AND k.keyword LIKE '%action%'
),
aggregated_movie_data AS (
    SELECT 
        movie_id,
        title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actor_names,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        COUNT(DISTINCT movie_id) AS total_movies
    FROM 
        movie_details
    GROUP BY 
        movie_id, title, production_year
)
SELECT 
    amd.movie_id,
    amd.title,
    amd.production_year,
    amd.actor_names,
    amd.keywords,
    amd.total_movies
FROM 
    aggregated_movie_data amd
ORDER BY 
    amd.production_year DESC,
    amd.total_movies DESC;
