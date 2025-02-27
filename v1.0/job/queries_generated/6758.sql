SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS role_type, 
    co.name AS company_name, 
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000 
    AND co.country_code = 'USA' 
    AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    t.production_year DESC, a.name;
