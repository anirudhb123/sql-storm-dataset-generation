SELECT 
    p.name AS person_name,
    a.title AS movie_title,
    a.production_year,
    r.role AS person_role,
    c.kind AS company_type,
    k.keyword AS movie_keyword
FROM 
    cast_info ci
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    aka_title a ON ci.movie_id = a.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.production_year >= 2000
ORDER BY 
    a.production_year DESC, 
    p.name;
