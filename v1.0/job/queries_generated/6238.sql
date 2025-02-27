SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    co.name AS company_name,
    ki.keyword AS movie_keyword,
    ti.info AS movie_info,
    r.role AS role_type,
    ti.production_year AS release_year
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
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
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    ti.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
    AND t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, ak.name ASC;
