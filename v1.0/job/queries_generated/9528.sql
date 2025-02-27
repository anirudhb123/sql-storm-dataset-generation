WITH movie_details AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        n.gender,
        p.info AS director_info
    FROM 
        aka_title a
    INNER JOIN 
        movie_companies mc ON a.id = mc.movie_id
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    INNER JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id AND ci.person_role_id = (SELECT id FROM role_type WHERE role = 'director')
    LEFT JOIN 
        name n ON ci.person_id = n.id
    LEFT JOIN 
        person_info p ON n.id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    WHERE 
        a.production_year >= 2000
), aggregated_data AS (
    SELECT 
        movie_id,
        title,
        production_year,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT gender, ', ') AS genders,
        STRING_AGG(DISTINCT director_info, ', ') AS directors_info
    FROM 
        movie_details
    GROUP BY 
        movie_id, title, production_year
)
SELECT 
    *
FROM 
    aggregated_data
ORDER BY 
    production_year DESC, title;
