SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS character_role,
    co.name AS company_name,
    ki.keyword AS movie_keyword,
    m.info AS movie_info 
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
ORDER BY 
    t.production_year DESC, a.name;
