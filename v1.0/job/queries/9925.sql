WITH movie_data AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS cast_type,
        k.keyword AS genre
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id AND ci.nr_order = 1
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    WHERE 
        t.production_year >= 2000
),
aggregated_data AS (
    SELECT 
        production_year,
        COUNT(*) AS total_movies,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT genre, ', ') AS genres
    FROM 
        movie_data
    GROUP BY 
        production_year
)
SELECT 
    production_year,
    total_movies,
    actors,
    genres
FROM 
    aggregated_data
ORDER BY 
    production_year DESC;
