WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COALESCE(ka.name, '') AS aka_name,
        c.name AS company_name,
        r.role AS role_description,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        aka_title ka ON t.id = ka.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year, ka.name, c.name, r.role
),
ranked_movies AS (
    SELECT 
        movie_title,
        production_year,
        aka_name,
        company_name,
        role_description,
        keywords,
        cast_count,
        RANK() OVER (ORDER BY production_year DESC, cast_count DESC) AS rank
    FROM 
        movie_details
)
SELECT 
    rank,
    movie_title,
    production_year,
    aka_name,
    company_name,
    role_description,
    keywords,
    cast_count
FROM 
    ranked_movies
WHERE 
    rank <= 10
ORDER BY 
    rank;
