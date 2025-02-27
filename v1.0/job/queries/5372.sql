SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS actor_role,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    comp.name AS company_name,
    ct.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year > 2000
    AND ct.kind = 'Distributor'
ORDER BY 
    t.production_year DESC, a.name;
