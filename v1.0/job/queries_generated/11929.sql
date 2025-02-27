SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    r.role AS person_role
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type c ON mc.company_type_id = c.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, p.name;
