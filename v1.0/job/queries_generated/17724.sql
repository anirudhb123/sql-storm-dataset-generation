SELECT 
    t.title, 
    ak.name AS aka_name, 
    c.note AS cast_note, 
    p.info AS person_info 
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    aka_title ak ON ak.movie_id = t.id
JOIN 
    cast_info c ON c.movie_id = t.id
JOIN 
    aka_name akn ON akn.person_id = c.person_id
JOIN 
    person_info p ON p.person_id = akn.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
