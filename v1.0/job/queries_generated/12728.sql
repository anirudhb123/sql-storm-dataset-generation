SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nf_order AS cast_order,
    r.role AS role_type,
    m.production_year,
    cname.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name cname ON mc.company_id = cname.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Some specific info')
ORDER BY 
    m.production_year DESC, aka_name;
