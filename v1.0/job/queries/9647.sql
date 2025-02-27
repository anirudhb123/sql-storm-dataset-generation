SELECT 
    ak.name AS aka_name,
    ct.kind AS company_type,
    t.title AS movie_title,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ak.name ILIKE '%Smith%'
    AND t.production_year > 2000
ORDER BY 
    t.production_year DESC, ak.name ASC
LIMIT 100;
