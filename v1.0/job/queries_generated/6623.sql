SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    p.gender AS actor_gender, 
    ci.kind AS company_type, 
    ki.keyword AS movie_keyword 
FROM 
    aka_name ak 
JOIN 
    cast_info c ON ak.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword ki ON mk.keyword_id = ki.id 
JOIN 
    person_info p ON ak.person_id = p.person_id 
JOIN 
    role_type r ON c.role_id = r.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
AND 
    ak.name IS NOT NULL 
ORDER BY 
    t.production_year DESC, 
    c.nr_order ASC;
