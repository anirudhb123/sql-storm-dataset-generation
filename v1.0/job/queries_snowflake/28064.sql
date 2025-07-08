
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        c.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title t
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
        AND k.keyword LIKE '%drama%'
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.kind
),
ranked_movies AS (
    SELECT 
        md.*,
        RANK() OVER (PARTITION BY md.keyword ORDER BY md.company_count DESC) AS company_rank
    FROM 
        movie_details md
)
SELECT 
    movie_id,
    title,
    production_year,
    keyword,
    cast_names,
    company_type,
    company_count,
    company_rank
FROM 
    ranked_movies
WHERE 
    company_rank <= 5
ORDER BY 
    keyword, company_count DESC, production_year DESC;
