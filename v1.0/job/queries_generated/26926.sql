WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
),
cast_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_type
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
info_details AS (
    SELECT 
        mi.movie_id,
        mi.info AS movie_info,
        it.info AS info_type
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.movie_keyword,
    md.company_name,
    md.company_type,
    cd.actor_name,
    cd.role_type,
    id.movie_info
FROM 
    movie_details md
LEFT JOIN 
    cast_details cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    info_details id ON md.movie_id = id.movie_id
ORDER BY 
    md.production_year DESC, md.movie_title;
