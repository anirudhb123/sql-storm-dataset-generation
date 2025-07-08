
WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        LISTAGG(DISTINCT c.kind, ', ') WITHIN GROUP (ORDER BY c.kind) AS company_types
    FROM 
        title t
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
        LOWER(t.title) LIKE '%%love%%'
    GROUP BY 
        t.title, t.production_year, a.name
),
ranked_movies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title) AS rank
    FROM 
        movie_data
)
SELECT 
    *
FROM 
    ranked_movies
WHERE 
    rank <= 3
ORDER BY 
    production_year DESC, movie_title;
