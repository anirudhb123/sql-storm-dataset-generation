
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS role_description,
        ct.kind AS company_type,
        k.keyword AS movie_keyword,
        pi.info AS person_info
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.id = cc.subject_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        role_type r ON r.id = ci.role_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        person_info pi ON pi.person_id = ci.person_id
    WHERE 
        t.production_year >= 2000
        AND k.keyword IS NOT NULL
),
aggregated_data AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT role_description, ', ') AS roles,
        STRING_AGG(DISTINCT company_type, ', ') AS companies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT person_info, ', ') AS person_infos
    FROM 
        movie_details
    GROUP BY 
        movie_title, 
        production_year
)
SELECT 
    movie_title,
    production_year,
    actors,
    roles,
    companies,
    keywords,
    person_infos
FROM 
    aggregated_data
ORDER BY 
    production_year DESC, movie_title;
