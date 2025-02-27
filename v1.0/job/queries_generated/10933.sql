SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    ci.note AS role_note,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword k ON t.id = k.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
