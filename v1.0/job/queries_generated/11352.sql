SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    k.keyword AS movie_keyword,
    com.name AS company_name,
    ci.kind AS company_type,
    mi.info AS movie_info,
    r.role AS role_type,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name com ON mc.company_id = com.id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, a.name;
