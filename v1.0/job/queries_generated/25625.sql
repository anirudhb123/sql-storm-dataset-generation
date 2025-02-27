WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.role AS character_name,
        a.name AS actor_name,
        i.info AS additional_info
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type c ON ci.role_id = c.id
    LEFT JOIN 
        movie_info i ON t.id = i.movie_id
    WHERE 
        t.production_year >= 2000
        AND LOWER(i.info) LIKE '%award%' 
        AND a.name IS NOT NULL
),
keyword_summary AS (
    SELECT 
        md.keyword AS movie_keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM 
        keyword md
    JOIN 
        movie_keyword mk ON md.id = mk.keyword_id
    GROUP BY 
        md.keyword
    HAVING 
        COUNT(mk.movie_id) > 1
),
company_summary AS (
    SELECT 
        c.name AS company_name,
        COUNT(mc.movie_id) AS produced_movies
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    GROUP BY 
        c.name
    ORDER BY 
        produced_movies DESC
)
SELECT 
    md.movie_title, 
    md.production_year, 
    md.actor_name, 
    md.character_name, 
    ks.movie_keyword, 
    cs.company_name, 
    cs.produced_movies
FROM 
    movie_details md
JOIN 
    keyword_summary ks ON md.movie_title LIKE '%' || ks.movie_keyword || '%' 
JOIN 
    company_summary cs ON md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, 
    md.actor_name;
