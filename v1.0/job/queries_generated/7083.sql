WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name) AS actor_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        STRING_AGG(DISTINCT c.kind) AS company_types
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_type c ON c.id = mc.company_type_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
ranked_movies AS (
    SELECT 
        md.*,
        RANK() OVER (ORDER BY production_year DESC) AS year_rank
    FROM 
        movie_data md
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_names,
    keywords,
    company_types,
    year_rank
FROM 
    ranked_movies
WHERE 
    year_rank <= 10
ORDER BY 
    production_year DESC;
