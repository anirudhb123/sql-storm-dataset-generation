SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS actor_role,
    c.kind AS company_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    company_name cn ON t.id = (SELECT mc.movie_id FROM movie_companies mc WHERE mc.movie_id = t.id LIMIT 1)
JOIN 
    company_type c ON cn.id = (SELECT mc.company_type_id FROM movie_companies mc WHERE mc.movie_id = t.id LIMIT 1)
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year > 2000 
    AND a.name ILIKE '%Smith%' 
ORDER BY 
    t.production_year DESC, 
    a.name;
