WITH movie_cast AS (
    SELECT 
        c.id AS cast_id,
        p.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        r.role AS role_description
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        title t ON c.movie_id = t.id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
keyword_associations AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
company_details AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
movie_info_details AS (
    SELECT 
        mi.movie_id,
        mi.info AS movie_description
    FROM 
        movie_info mi
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
)
SELECT 
    mc.cast_id,
    mc.actor_name,
    mc.movie_title,
    mc.production_year,
    mc.kind_id,
    mc.role_description,
    STRING_AGG(DISTINCT ka.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT co.company_name || ' (' || co.company_type || ')', '; ') AS companies,
    mi.movie_description
FROM 
    movie_cast mc
LEFT JOIN 
    keyword_associations ka ON mc.movie_title = (SELECT title FROM title WHERE id = mc.movie_id)
LEFT JOIN 
    company_details co ON mc.movie_id = co.movie_id
LEFT JOIN 
    movie_info_details mi ON mc.movie_id = mi.movie_id
WHERE 
    mc.production_year >= 2000 
GROUP BY 
    mc.cast_id, mc.actor_name, mc.movie_title, mc.production_year, mc.kind_id, mc.role_description, mi.movie_description
ORDER BY 
    mc.production_year DESC, mc.actor_name;
