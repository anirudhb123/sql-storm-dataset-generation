
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ct.kind AS company_type,
        a.name AS actor_name,
        r.role AS role_name,
        k.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND ct.kind LIKE '%Film%'
    ORDER BY 
        t.production_year, a.name
),
aggregated_data AS (
    SELECT 
        movie_title,
        production_year,
        company_type,
        LISTAGG(DISTINCT actor_name, ', ') WITHIN GROUP (ORDER BY actor_name) AS actors,
        LISTAGG(DISTINCT role_name, ', ') WITHIN GROUP (ORDER BY role_name) AS roles,
        LISTAGG(DISTINCT movie_keyword, ', ') WITHIN GROUP (ORDER BY movie_keyword) AS keywords
    FROM 
        movie_details
    GROUP BY 
        movie_title, production_year, company_type
)
SELECT 
    * 
FROM 
    aggregated_data
ORDER BY 
    production_year ASC, movie_title;
