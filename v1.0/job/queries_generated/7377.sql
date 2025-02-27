SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    ci.note AS cast_note,
    co.name AS company_name,
    ci.nr_order AS role_order
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name LIKE '%Smith%'
    AND t.production_year >= 2000
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
ORDER BY 
    t.production_year DESC, a.name ASC;
