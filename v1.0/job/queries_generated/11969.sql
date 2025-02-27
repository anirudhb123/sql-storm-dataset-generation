SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    c.role AS person_role,
    k.keyword AS movie_keyword,
    com.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info p ON ci.person_id = p.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name com ON mc.company_id = com.id
ORDER BY 
    t.production_year DESC, a.name;
