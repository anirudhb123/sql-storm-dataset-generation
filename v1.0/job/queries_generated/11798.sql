SELECT 
    na.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year AS production_year,
    ci.note AS role_note,
    ct.kind AS company_type,
    co.name AS company_name
FROM 
    cast_info ci
JOIN 
    aka_name na ON ci.person_id = na.person_id
JOIN 
    aka_title ti ON ci.movie_id = ti.movie_id
JOIN 
    movie_companies mc ON ti.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    ti.production_year >= 2000
ORDER BY 
    ti.production_year DESC, na.name;
