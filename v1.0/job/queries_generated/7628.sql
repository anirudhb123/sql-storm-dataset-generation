SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    c.note AS role_note,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    ti.info AS additional_info
FROM 
    name a
JOIN 
    cast_info c ON a.id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON ti.id = mi.info_type_id
WHERE 
    t.production_year > 2000
AND 
    c.nr_order IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    a.name, 
    c.nr_order;
