SELECT 
    t.title AS movie_title,
    p.name AS actor_name,
    a.name AS aka_name,
    c.kind AS company_type,
    w.keyword AS keyword
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    name p ON ci.person_id = p.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword w ON mk.keyword_id = w.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, p.name;
