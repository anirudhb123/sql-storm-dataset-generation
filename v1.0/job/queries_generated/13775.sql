SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    comp.name AS company_name,
    tp.kind AS company_type,
    ti.info AS movie_info,
    r.role AS role_type
FROM
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    company_type tp ON mc.company_type_id = tp.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    role_type r ON c.role_id = r.id
ORDER BY 
    t.production_year DESC, a.name;
