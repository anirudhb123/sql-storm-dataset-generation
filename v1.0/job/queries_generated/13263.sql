SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    a.name AS aka_name
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    company_name c ON ci.movie_id = c.imdb_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    t.title, 
    p.name;
