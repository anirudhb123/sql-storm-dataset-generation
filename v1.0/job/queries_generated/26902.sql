WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ') AS actors,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS companies
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
filtered_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        actors,
        keywords,
        companies
    FROM 
        movie_details
    WHERE 
        LENGTH(actors) > 0 
        AND LENGTH(keywords) > 0
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    actors,
    keywords,
    companies
FROM 
    filtered_movies
ORDER BY 
    production_year DESC, 
    movie_title;
