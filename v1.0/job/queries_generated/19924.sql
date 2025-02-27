SELECT 
    akn.name AS aka_name,
    tit.title AS movie_title,
    pers.name AS person_name,
    rty.role AS role,
    comp.name AS company_name
FROM 
    aka_name akn
JOIN 
    cast_info ci ON akn.person_id = ci.person_id
JOIN 
    title tit ON ci.movie_id = tit.id
JOIN 
    person_info pi ON akn.person_id = pi.person_id
JOIN 
    role_type rty ON ci.role_id = rty.id
JOIN 
    movie_companies mc ON tit.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
WHERE 
    tit.production_year = 2020
ORDER BY 
    akn.name, tit.title;
