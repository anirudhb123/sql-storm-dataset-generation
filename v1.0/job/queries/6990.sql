SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    t.production_year, 
    c.person_role_id, 
    r.role, 
    co.name AS company_name, 
    g.kind AS genre, 
    k.keyword AS movie_keyword 
FROM 
    aka_name ak 
JOIN 
    cast_info c ON ak.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    role_type r ON c.role_id = r.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    kind_type g ON t.kind_id = g.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year >= 2000 
    AND co.country_code = 'USA' 
    AND k.keyword LIKE '%action%' 
ORDER BY 
    t.production_year DESC, ak.name ASC;
