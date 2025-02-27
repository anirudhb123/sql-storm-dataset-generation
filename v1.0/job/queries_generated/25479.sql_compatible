
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
ranked_movies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.actors,
        md.keywords,
        md.companies,
        RANK() OVER (ORDER BY md.production_year DESC) AS rank
    FROM 
        movie_details md
)

SELECT 
    rm.rank,
    rm.movie_title,
    rm.production_year,
    rm.actors,
    rm.keywords,
    rm.companies
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 10 
ORDER BY 
    rm.rank;
