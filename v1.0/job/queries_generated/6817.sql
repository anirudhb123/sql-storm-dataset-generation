SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS character_name,
    mt.kind AS movie_type,
    pc.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    char_name c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    person_info pc ON a.person_id = pc.person_id
WHERE 
    t.production_year >= 2000 AND
    it.info = 'Budget' AND
    cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name;
