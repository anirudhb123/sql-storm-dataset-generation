WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS genre,
        c.name AS company_name,
        a.name AS actor_name
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
        AND a.name IS NOT NULL
),
aggregated_details AS (
    SELECT
        title_id,
        title,
        production_year,
        STRING_AGG(DISTINCT genre, ', ') AS genres,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors
    FROM 
        movie_details
    GROUP BY 
        title_id, title, production_year
)
SELECT 
    title,
    production_year,
    genres,
    companies,
    actors
FROM 
    aggregated_details
ORDER BY 
    production_year DESC, title;

