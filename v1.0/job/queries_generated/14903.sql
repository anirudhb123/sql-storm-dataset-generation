SELECT 
    p.name AS person_name,
    t.title AS movie_title,
    a.name AS aka_name,
    ci.note AS cast_note,
    k.keyword AS movie_keyword
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON ci.person_id = pi.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, p.name;
