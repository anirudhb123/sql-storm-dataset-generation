SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    m.info AS movie_info 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
JOIN 
    movie_info m ON t.id = m.movie_id 
WHERE 
    t.production_year >= 2000 
    AND cn.country_code = 'USA' 
    AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office') 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
