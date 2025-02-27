SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    ci.note AS character_name,
    p.info AS personal_info,
    ct.kind AS company_type,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    company_name cn ON cn.id IN (SELECT company_id FROM movie_companies mc WHERE mc.movie_id = t.id)
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info m ON m.movie_id = t.id
WHERE 
    a.name LIKE '%John%'
    AND t.production_year > 2000
    AND ct.kind = 'Distributor'
ORDER BY 
    t.production_year DESC, a.name;
