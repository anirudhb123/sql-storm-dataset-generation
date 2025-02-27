SELECT 
    t.title AS movie_title, 
    p.name AS person_name, 
    c.kind AS company_type, 
    r.role AS role,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    keyword k ON t.id = k.id
JOIN 
    movie_info i ON t.id = i.movie_id
WHERE 
    t.production_year = 2020
ORDER BY 
    t.title, p.name;
