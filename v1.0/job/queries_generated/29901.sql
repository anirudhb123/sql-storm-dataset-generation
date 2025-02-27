WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        c.country_code
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
cast_details AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        r.role AS actor_role
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        role_type r ON ca.role_id = r.id
),
movie_info_details AS (
    SELECT 
        m.movie_id,
        mp.info AS movie_plot
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    WHERE 
        it.info = 'Plot'
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.movie_keyword,
    md.company_name,
    md.country_code,
    cd.actor_name,
    cd.actor_role,
    mid.movie_plot
FROM 
    movie_details md
LEFT JOIN 
    cast_details cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    movie_info_details mid ON md.movie_id = mid.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title;

