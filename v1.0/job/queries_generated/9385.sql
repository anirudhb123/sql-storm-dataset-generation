SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS cast_note,
    comp.name AS company_name,
    mi.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name LIKE 'J%'
    AND t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, a.name;
