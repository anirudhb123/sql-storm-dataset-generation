WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        r.role AS actor_role,
        GROUP_CONCAT(DISTINCT g.kind ORDER BY g.kind) AS genres
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        kind_type g ON t.kind_id = g.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND c.country_code = 'USA'
    GROUP BY 
        t.title, t.production_year, c.name, k.keyword, a.name, r.role
),
ranked_movies AS (
    SELECT 
        movie_details.*,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY production_year DESC, movie_title) AS rank
    FROM 
        movie_details
)
SELECT 
    rank,
    movie_title,
    production_year,
    company_name,
    movie_keyword,
    actor_name,
    actor_role,
    genres
FROM 
    ranked_movies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, rank;

This query retrieves the top 10 movies produced in the USA from 2000 to 2023, including their titles, production years, associated companies, keywords, leading actors, roles, and genres, while ranking them by year and title. The `WITH` clause is used to build a common table expression for movie details and then rank them.
