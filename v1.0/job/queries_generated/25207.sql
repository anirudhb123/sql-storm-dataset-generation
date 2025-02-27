WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS comp_type,
        COUNT(mk.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.title, 
        t.production_year, 
        a.name, 
        c.kind
),
ranked_movies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        comp_type,
        keyword_count,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        movie_data
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    comp_type,
    keyword_count,
    rank
FROM 
    ranked_movies
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, 
    rank;
