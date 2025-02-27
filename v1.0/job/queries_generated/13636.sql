SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    cn.name AS company_name,
    ci.kind AS company_type,
    k.keyword AS movie_keyword,
    r.role AS person_role,
    pi.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    person_info pi ON c.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
