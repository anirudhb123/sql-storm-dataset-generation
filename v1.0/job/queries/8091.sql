SELECT 
    ak.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year,
    co.name AS company_name,
    ct.kind AS company_type,
    rv.role AS role_type
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title ti ON ci.movie_id = ti.id
JOIN 
    movie_companies mc ON ti.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    role_type rv ON ci.role_id = rv.id
WHERE 
    ti.production_year BETWEEN 2000 AND 2023
    AND ct.kind = 'Production'
ORDER BY 
    ti.production_year DESC, ak.name;
