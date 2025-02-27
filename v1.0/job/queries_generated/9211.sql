SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    co.name AS company_name, 
    ti.info AS additional_info 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    info_type ti ON mi.info_type_id = ti.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND co.country_code = 'USA' 
    AND ti.info ILIKE '%Award%'
ORDER BY 
    a.name, t.production_year DESC;
