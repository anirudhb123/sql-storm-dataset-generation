SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    comp.name AS company_name,
    info.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_info info ON t.movie_id = info.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
