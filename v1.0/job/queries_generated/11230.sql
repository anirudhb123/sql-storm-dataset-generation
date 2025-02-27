SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    m.production_year,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title at ON at.movie_id = t.id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type ct ON ct.id = mc.company_type_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
