SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.role_id,
    p.info AS person_info,
    comp.name AS company_name,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i_t ON mi.info_type_id = i_t.id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year >= 2000 
    AND i_t.info = 'budget'
ORDER BY 
    ak.name, t.title;
