WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS cast_type,
        p.info AS person_info,
        k.keyword
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND c.kind = 'actor'
        AND t.title ILIKE '%adventure%'
),
aggregated_data AS (
    SELECT 
        title_id,
        title,
        production_year,
        ARRAY_AGG(DISTINCT actor_name) AS actors,
        ARRAY_AGG(DISTINCT cast_type) AS roles,
        ARRAY_AGG(DISTINCT person_info) AS additional_info,
        ARRAY_AGG(DISTINCT keyword) AS keywords
    FROM 
        movie_details
    GROUP BY 
        title_id, title, production_year
)
SELECT 
    ad.title,
    ad.production_year,
    STRING_AGG(DISTINCT ad.actors::text, ', ') AS actor_names,
    STRING_AGG(DISTINCT ad.roles::text, ', ') AS cast_roles,
    STRING_AGG(DISTINCT ad.additional_info::text, ', ') AS person_information,
    STRING_AGG(DISTINCT ad.keywords::text, ', ') AS movie_keywords
FROM 
    aggregated_data ad
GROUP BY 
    ad.title, ad.production_year
ORDER BY 
    ad.production_year DESC, ad.title;
