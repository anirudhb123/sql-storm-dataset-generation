SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    cc.name AS company_name,
    m.info AS movie_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cc ON mc.company_id = cc.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
    AND cc.country_code = 'USA'
    AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office')
ORDER BY 
    t.production_year DESC, 
    a.name;
