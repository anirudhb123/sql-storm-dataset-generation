SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    r.role AS actor_role, 
    c.name AS company_name, 
    k.keyword AS movie_keyword, 
    ti.info AS additional_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year > 2000 
    AND c.country_code = 'USA' 
    AND k.keyword LIKE '%action%' 
ORDER BY 
    a.name, t.production_year DESC;
