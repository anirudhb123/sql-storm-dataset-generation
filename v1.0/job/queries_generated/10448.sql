SELECT 
    akn.name AS aka_name,
    tit.title AS movie_title,
    per.name AS person_name,
    rt.role AS role,
    comp.name AS company_name,
    k.keyword AS keyword,
    mt.info AS movie_info
FROM 
    aka_name akn
JOIN 
    cast_info ci ON akn.person_id = ci.person_id
JOIN 
    title tit ON ci.movie_id = tit.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_companies mc ON tit.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON tit.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mt ON tit.id = mt.movie_id
WHERE 
    tit.production_year >= 2000
ORDER BY 
    tit.production_year DESC, akn.name;
