SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    role_type r ON r.id = ci.role_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type c ON c.id = mc.company_type_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
JOIN 
    movie_info mi ON mi.movie_id = t.id
JOIN 
    info_type i ON i.id = mi.info_type_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, t.title, a.name;
