SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.name AS company_name,
    r.role AS actor_role,
    p.info AS actor_info,
    k.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
    AND ak.name IS NOT NULL
    AND c.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    ak.name ASC;
