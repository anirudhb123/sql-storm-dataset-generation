SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    r.role AS role,
    p.info AS person_info,
    c.kind AS company_type
FROM 
    aka_title ak
JOIN 
    title t ON ak.movie_id = t.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name akn ON ci.person_id = akn.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    person_info p ON akn.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    ak.name;
