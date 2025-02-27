SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS cast_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    company_name cn ON cn.id IN (SELECT company_id FROM movie_companies mc WHERE mc.movie_id = t.id)
JOIN 
    movie_info m ON m.movie_id = t.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type c ON ci.role_id = c.id
JOIN 
    name p ON a.person_id = p.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
