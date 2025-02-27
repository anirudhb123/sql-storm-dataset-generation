SELECT 
    akn.name AS aka_name,
    ttl.title AS movie_title,
    cst.nr_order, 
    cst.note AS cast_note,
    co.name AS company_name,
    kt.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    aka_name akn
JOIN 
    cast_info cst ON akn.person_id = cst.person_id
JOIN 
    aka_title ttl ON cst.movie_id = ttl.movie_id
JOIN 
    movie_companies mco ON ttl.id = mco.movie_id
JOIN 
    company_name co ON mco.company_id = co.id
JOIN 
    movie_keyword mk ON ttl.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    movie_info mi ON ttl.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    ttl.production_year BETWEEN 2000 AND 2023 
    AND cst.role_id IN (SELECT id FROM role_type WHERE role LIKE '%actor%')
ORDER BY 
    ttl.production_year DESC, akn.name;
