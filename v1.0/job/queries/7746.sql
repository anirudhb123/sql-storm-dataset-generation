SELECT 
    ak.name AS actor_name, 
    tit.title AS movie_title, 
    comp.name AS company_name, 
    k.keyword AS movie_keyword, 
    pi.info AS actor_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title tit ON ci.movie_id = tit.id
JOIN 
    movie_companies mc ON tit.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON tit.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    tit.production_year BETWEEN 2000 AND 2023
    AND comp.country_code = 'USA'
    AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate')
ORDER BY 
    tit.production_year DESC, ak.name;
