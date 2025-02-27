SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    ctype.kind AS compensation_type,
    m.type AS movie_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword k ON c.movie_id = k.movie_id
JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
JOIN 
    company_type ctype ON mc.company_type_id = ctype.id
JOIN 
    kind_type m ON t.kind_id = m.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
