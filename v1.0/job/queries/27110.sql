WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        a.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year > 2000
        AND k.keyword IS NOT NULL
),
grouped_movie_details AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors
    FROM 
        movie_details
    GROUP BY 
        movie_id, movie_title, production_year
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    keywords,
    companies,
    actors
FROM 
    grouped_movie_details
ORDER BY 
    production_year DESC, movie_title;
