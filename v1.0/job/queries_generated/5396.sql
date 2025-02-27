SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    cw.name AS company_name,
    m.production_year,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type kty ON t.kind_id = kty.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cw ON mc.company_id = cw.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name ILIKE '%Smith%' 
    AND m.production_year > 2000
ORDER BY 
    m.production_year DESC, a.name;
