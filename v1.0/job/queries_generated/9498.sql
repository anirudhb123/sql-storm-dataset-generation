SELECT 
    ak.name AS aka_name,
    ti.title AS movie_title,
    ci.nr_order AS cast_order,
    cn.name AS company_name,
    kt.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title ti ON ci.movie_id = ti.id
JOIN 
    movie_companies mc ON ti.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON ti.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    ti.production_year BETWEEN 2000 AND 2020
    AND ak.imdb_index IS NOT NULL
    AND ci.nr_order IS NOT NULL
ORDER BY 
    ti.production_year DESC, 
    ak.name ASC, 
    ci.nr_order ASC;
