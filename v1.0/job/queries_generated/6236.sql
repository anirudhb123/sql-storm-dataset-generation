WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        ak.name AS actor_name,
        k.keyword AS keyword
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND cn.country_code = 'USA'
),
aggregated_data AS (
    SELECT 
        movie_title, 
        production_year, 
        company_type,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM 
        movie_data
    GROUP BY 
        movie_title, production_year, company_type
)
SELECT 
    production_year,
    company_type,
    COUNT(movie_title) AS total_movies,
    STRING_AGG(movie_title, '; ') AS movie_list,
    STRING_AGG(actors, '; ') AS all_actors,
    STRING_AGG(keywords, '; ') AS all_keywords
FROM 
    aggregated_data
GROUP BY 
    production_year, company_type
ORDER BY 
    production_year DESC, total_movies DESC;
