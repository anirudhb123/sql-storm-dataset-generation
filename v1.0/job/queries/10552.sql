SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.name AS company_name,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
JOIN 
    cast_info ci ON a.person_id = ci.person_id AND t.id = ci.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
