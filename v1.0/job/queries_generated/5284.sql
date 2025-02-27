SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.role_id,
    p.info AS person_info,
    cmp.name AS company_name,
    kt.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cmp ON mc.company_id = cmp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    t.production_year >= 2000
    AND ak.name IS NOT NULL
    AND cmp.country_code = 'USA'
ORDER BY 
    t.production_year DESC, ak.name;
