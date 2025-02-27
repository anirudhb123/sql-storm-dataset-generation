SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    co.name AS company_name,
    ti.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND co.country_code = 'USA'
    AND ti.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
ORDER BY 
    t.production_year DESC, 
    actor_name ASC
LIMIT 100;
