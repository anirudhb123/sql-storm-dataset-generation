SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS role_order, 
    co.name AS company_name, 
    ki.keyword AS movie_keyword, 
    ti.info AS movie_info
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword ki ON mk.keyword_id = ki.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND co.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, a.name, t.title;
