SELECT 
    t.title,
    t.production_year,
    a.name AS actor_name,
    ct.kind AS company_type,
    ki.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year, a.name;
