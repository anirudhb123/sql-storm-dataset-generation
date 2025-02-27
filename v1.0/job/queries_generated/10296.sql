SELECT 
    a.name AS aka_name, 
    at.title AS movie_title, 
    p.gender AS person_gender, 
    c.note AS cast_note, 
    t.production_year,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    name p ON c.person_id = p.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
