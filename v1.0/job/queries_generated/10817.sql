SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    cn.name AS company_name,
    ki.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC;
