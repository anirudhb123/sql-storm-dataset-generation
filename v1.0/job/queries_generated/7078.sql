SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    p.info AS person_info,
    K.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword K ON mk.keyword_id = K.id
WHERE 
    t.production_year > 2000
    AND K.keyword LIKE 'Action%'
ORDER BY 
    a.name, t.production_year DESC;
