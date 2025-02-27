SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.role_id,
    p.info AS person_info,
    kt.keyword AS movie_keyword
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
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
