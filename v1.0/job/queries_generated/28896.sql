WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year, 
        a.name AS actor_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
        COUNT(DISTINCT CONCAT(ci.person_id, ' ', ci.role_id)) AS num_roles
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND a.name IS NOT NULL
    GROUP BY 
        t.title, t.production_year, a.name
),

ranked_movies AS (
    SELECT 
        movie_title, 
        production_year, 
        actor_name,
        keywords, 
        company_types, 
        num_roles,
        RANK() OVER (PARTITION BY production_year ORDER BY num_roles DESC) AS rank
    FROM 
        movie_details
)

SELECT 
    *
FROM 
    ranked_movies
WHERE 
    rank <= 5
ORDER BY 
    production_year, rank;
