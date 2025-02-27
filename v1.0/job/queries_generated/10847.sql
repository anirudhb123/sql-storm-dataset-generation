SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS person_role,
    comp.name AS company_name,
    k.keyword AS movie_keyword
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
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year, t.title;
