SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS cast_type,
    co.name AS company_name,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    person_info p ON p.person_id = ak.person_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000 
    AND co.country_code = 'US'
    AND k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, ak.name;
