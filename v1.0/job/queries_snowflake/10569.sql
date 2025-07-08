SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.person_role_id, 
    p.info AS person_info, 
    k.keyword AS movie_keyword, 
    comp.kind AS company_type,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_type comp ON mc.company_type_id = comp.id
JOIN 
    movie_info ti ON t.movie_id = ti.movie_id
WHERE 
    ti.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
AND 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
