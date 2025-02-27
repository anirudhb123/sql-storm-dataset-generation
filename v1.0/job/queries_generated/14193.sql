SELECT 
    at.title AS movie_title,
    an.name AS actor_name,
    ct.kind AS cast_type,
    cc.name AS company_name,
    ti.info AS movie_info,
    kw.keyword AS movie_keyword
FROM 
    aka_title at
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_name cc ON mc.company_id = cc.id
JOIN 
    movie_info mi ON at.id = mi.movie_id
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    comp_cast_type ct ON ci.role_id = ct.id
WHERE 
    at.production_year >= 2000
ORDER BY 
    at.title, an.name;
