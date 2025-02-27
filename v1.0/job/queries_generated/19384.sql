SELECT 
    at.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS company_type,
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
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON at.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    at.production_year >= 2000
ORDER BY 
    at.title, ak.name;
