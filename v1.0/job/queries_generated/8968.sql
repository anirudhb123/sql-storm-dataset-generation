SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    cc.kind AS comp_cast_type, 
    m.name AS company_name, 
    k.keyword AS movie_keyword, 
    ti.info AS movie_info
FROM 
    cast_info c 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    movie_companies mc ON mc.movie_id = t.id 
JOIN 
    company_name m ON mc.company_id = m.id 
JOIN 
    movie_keyword mk ON mk.movie_id = t.id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_info mi ON mi.movie_id = t.id 
JOIN 
    info_type ti ON mi.info_type_id = ti.id 
WHERE 
    t.production_year > 2000 
    AND m.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    c.nr_order;
