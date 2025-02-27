SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    tc.kind AS company_type, 
    m.info AS movie_info, 
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    keyword k ON t.id = k.movie_id
WHERE 
    t.production_year > 2000 AND
    m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis')
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
