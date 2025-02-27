SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS character_role, 
    co.name AS company_name, 
    m.production_year, 
    k.keyword AS movie_keyword, 
    pi.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    m.production_year >= 2000 
    AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography') 
ORDER BY 
    a.name, 
    t.production_year DESC;
