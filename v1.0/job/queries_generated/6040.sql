SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    p.info AS person_info,
    m.year AS production_year,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    company_name co ON cc.subject_id = co.imdb_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    keyword k ON m.id = k.id
JOIN 
    info_type it ON m.info_type_id = it.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year > 2000
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    AND it.info = 'Summary'
ORDER BY 
    t.production_year DESC, a.name;
