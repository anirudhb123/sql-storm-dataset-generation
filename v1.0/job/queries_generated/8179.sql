WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        r.role AS person_role,
        a.name AS actor_name
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
        AND c.country_code = 'USA'
),
aggregated_data AS (
    SELECT 
        movie_id,
        title,
        production_year,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT actor_name || ' (' || person_role || ')', ', ') AS cast
    FROM 
        movie_details
    GROUP BY 
        movie_id, title, production_year
)
SELECT 
    movie_id,
    title,
    production_year,
    companies,
    keywords,
    cast
FROM 
    aggregated_data
ORDER BY 
    production_year DESC, title;
