SELECT 
    ak.name AS aka_name,
    ti.title AS title,
    ci.nr_order AS cast_order,
    cn.name AS company_name,
    mt.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title ti ON ci.movie_id = ti.movie_id
JOIN 
    movie_companies mc ON ti.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_info mi ON ti.id = mi.movie_id
WHERE 
    ti.production_year >= 2000
ORDER BY 
    ti.production_year DESC, 
    ak.name;
