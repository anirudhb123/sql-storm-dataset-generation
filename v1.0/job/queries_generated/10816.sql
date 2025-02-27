SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    comp.name AS company_name,
    k.keyword AS movie_keyword,
    mi.info AS movie_info,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = t.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON mi.movie_id = t.movie_id
JOIN 
    person_info p ON p.person_id = a.person_id
WHERE 
    t.production_year >= 2000 
ORDER BY 
    a.name, t.title;
