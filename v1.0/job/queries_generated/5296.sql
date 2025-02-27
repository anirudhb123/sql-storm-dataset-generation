SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.n

ote AS cast_note,
    ct.kind AS cast_type,
    co.name AS company_name,
    mi.info AS movie_info,
    m.production_year
FROM 
    aka_name an
JOIN 
    cast_info c ON an.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info pi ON c.person_id = pi.person_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
WHERE 
    t.production_year > 2000 
    AND an.name LIKE 'J%' 
    AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography') 
ORDER BY 
    m.production_year DESC, 
    actor_name ASC;
