SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.id AS cast_info_id,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, ak.name;
