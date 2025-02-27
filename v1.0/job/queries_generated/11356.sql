SELECT 
    p.name AS person_name,
    t.title AS movie_title,
    a.name AS aka_name,
    k.keyword AS movie_keyword,
    c.kind AS company_type,
    m.info AS movie_info
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
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, p.name ASC;
