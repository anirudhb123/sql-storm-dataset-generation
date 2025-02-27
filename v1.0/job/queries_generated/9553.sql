SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    r.role AS person_role,
    k.keyword AS movie_keyword,
    t.production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info pi ON ci.person_id = pi.person_id
JOIN 
    role_type r ON ci.person_role_id = r.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name ASC;
