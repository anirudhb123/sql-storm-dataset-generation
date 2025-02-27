SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    r.role AS role_type,
    ci.kind AS comp_cast_type,
    m.name AS company_name,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id
WHERE 
    t.production_year >= 2000 
ORDER BY 
    t.production_year DESC, aka_name;
