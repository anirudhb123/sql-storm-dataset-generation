SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    pc.info AS person_info,
    m.comp_name AS company_name,
    k.keyword AS movie_keyword,
    mt.info AS movie_additional_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    company_name m ON m.id = (SELECT company_id FROM movie_companies mc WHERE mc.movie_id = t.id LIMIT 1)
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year > 2000 AND
    k.keyword ILIKE '%action%' AND
    it.info ILIKE '%box office%' 
ORDER BY 
    t.production_year DESC, 
    a.name;
