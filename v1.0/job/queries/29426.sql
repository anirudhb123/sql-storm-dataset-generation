WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        rp.role AS role_name,
        mcn.name AS company_name,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rp ON ci.role_id = rp.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name mcn ON mc.company_id = mcn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    AND 
        ak.name ILIKE 'A%'
),
aggregated_data AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT role_name, ', ') AS roles,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        movie_details
    GROUP BY 
        movie_title, 
        production_year
)
SELECT 
    movie_title,
    production_year,
    actors,
    roles,
    companies,
    keywords
FROM 
    aggregated_data
ORDER BY 
    production_year DESC, 
    movie_title;
