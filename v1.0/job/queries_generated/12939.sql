SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    ca.note AS cast_note,
    p.info AS person_info,
    r.role AS role_type,
    c.name AS company_name,
    k.keyword AS keyword
FROM 
    aka_name a
JOIN 
    cast_info ca ON a.person_id = ca.person_id
JOIN 
    title t ON ca.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type r ON ca.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
