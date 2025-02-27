WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ak.kind AS actor_role,
        kc.keyword AS keyword_used,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name AS c ON mc.company_id = c.id
    LEFT JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year IS NOT NULL
),
grouped_details AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT actor_role, ', ') AS roles,
        STRING_AGG(DISTINCT keyword_used, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT company_type, ', ') AS company_types
    FROM 
        movie_details
    GROUP BY 
        movie_title, production_year
)

SELECT 
    movie_title,
    production_year,
    actors,
    roles,
    keywords,
    companies,
    company_types
FROM 
    grouped_details
ORDER BY 
    production_year DESC, 
    movie_title;
