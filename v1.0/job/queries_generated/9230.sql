SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    cn.name AS company_name, 
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
    company_name cn ON mc.company_id = cn.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    info_type ti ON mi.info_type_id = ti.id 
WHERE 
    a.name ILIKE '%Smith%' 
    AND t.production_year > 2000 
    AND c.nr_order <= 3 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
