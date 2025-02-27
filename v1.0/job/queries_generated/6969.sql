SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    t.production_year,
    c.note AS character_role,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND k.keyword ILIKE '%action%'
ORDER BY 
    t.production_year DESC, 
    a.name;
