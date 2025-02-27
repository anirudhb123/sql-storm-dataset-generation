SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.note AS character_note,
    comp.name AS company_name,
    k.keyword AS movie_keyword,
    m.info AS movie_info
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON a.person_id = c.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON m.movie_id = t.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
