SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ct.kind AS company_type,
    c.name AS company_name,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mkw ON t.id = mkw.movie_id
JOIN 
    keyword k ON mkw.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
