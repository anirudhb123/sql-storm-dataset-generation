SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    c.name AS company_name,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON c.id = mc.company_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON k.id = mk.keyword_id
JOIN 
    comp_cast_type ct ON ci.role_id = ct.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    t.title, 
    a.name;
