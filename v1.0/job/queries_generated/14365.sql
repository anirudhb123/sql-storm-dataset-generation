SELECT 
    akn.name AS aka_name,
    tit.title AS movie_title,
    per.name AS person_name,
    rol.role AS person_role,
    comp.name AS company_name,
    info.info AS movie_info,
    kw.keyword AS movie_keyword
FROM 
    aka_name akn
JOIN 
    cast_info ci ON akn.person_id = ci.person_id
JOIN 
    title tit ON ci.movie_id = tit.id
JOIN 
    role_type rol ON ci.role_id = rol.id
JOIN 
    movie_companies mc ON tit.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_info mi ON tit.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    movie_keyword mk ON tit.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    tit.production_year >= 2000
ORDER BY 
    tit.production_year DESC, akn.name ASC;
