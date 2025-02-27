SELECT 
    at.title AS movie_title,
    ak.name AS actor_name,
    ci.nr_order AS cast_order,
    ct.kind AS company_type,
    cnt.name AS company_name,
    ti.info AS movie_info,
    kw.keyword AS movie_keyword
FROM 
    aka_title at
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_name cnt ON mc.company_id = cnt.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
LEFT JOIN 
    info_type ti ON mi.info_type_id = ti.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    at.production_year >= 2000
ORDER BY 
    at.production_year DESC, 
    ak.name;
