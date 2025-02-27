SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    c.note AS cast_note,
    ci.kind AS company_type,
    ti.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    movie_info mi ON t.movie_id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
ORDER BY 
    t.production_year DESC,
    a.name;
