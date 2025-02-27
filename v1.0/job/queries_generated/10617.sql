SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    c.kind AS company_type
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    company_name cn ON mi.info_type_id = cn.imdb_id
JOIN 
    company_type c ON cn.id = c.id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, ak.name;
