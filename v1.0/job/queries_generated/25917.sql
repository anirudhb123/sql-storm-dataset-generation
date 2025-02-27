WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        n.gender AS actor_gender,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        c.name AS company_name
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        role_type r ON r.id = ci.role_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        info_type it ON it.id IN (
            SELECT info_type_id FROM movie_info WHERE movie_id = t.id
        )
    LEFT JOIN 
        movie_info m_info ON m_info.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year, a.name, r.role, n.gender, c.name
    ORDER BY 
        production_year DESC, movie_title ASC
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    actor_name,
    actor_role,
    actor_gender,
    keywords,
    company_name
FROM 
    movie_data
WHERE 
    production_year >= 2000
    AND actor_gender = 'F'
    AND movie_title LIKE '%Love%'
    AND keywords ILIKE '%Drama%'
ORDER BY 
    actor_name;
