SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    cpt.kind AS company_type, 
    ci.note AS cast_note, 
    mi.info AS movie_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type cpt ON mc.company_type_id = cpt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 AND 
    cpt.kind = 'Distributor'
ORDER BY 
    t.production_year DESC, 
    a.name ASC
LIMIT 10;
