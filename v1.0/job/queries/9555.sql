SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_id,
    c.nr_order AS role_order,
    co.name AS company_name,
    co.country_code AS company_country,
    k.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON mi.movie_id = t.id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    k.keyword ILIKE '%action%'
ORDER BY 
    a.name, t.production_year DESC, co.name;
