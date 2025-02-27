SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    p.info AS actor_info,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    comp.name AS company_name,
    i.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year > 2000 
    AND a.name LIKE 'J%'
ORDER BY 
    t.production_year DESC, 
    a.name;
