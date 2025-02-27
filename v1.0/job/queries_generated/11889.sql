SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    p.name AS person_name,
    m.production_year,
    k.keyword
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name p ON c.person_id = p.imdb_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    ak.name;
