SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    cii.nr_order AS cast_order,
    cn.name AS company_name,
    ti.info AS movie_info,
    kt.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info cii ON ak.person_id = cii.person_id
JOIN 
    title t ON cii.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    t.production_year > 2000
    AND ak.name ILIKE '%Smith%'
ORDER BY 
    t.production_year DESC, 
    ak.name ASC, 
    cii.nr_order ASC;
