SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    m.company_id,
    c.nr_order,
    i.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info c ON cc.subject_id = c.person_id 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    movie_companies m ON t.id = m.movie_id 
JOIN 
    info_type it ON it.id = m.company_type_id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year > 2000 
    AND (EXISTS (SELECT 1 FROM person_info pi WHERE pi.person_id = a.person_id AND pi.info_type_id = 1))
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
