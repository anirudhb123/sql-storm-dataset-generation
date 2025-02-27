SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.role_id AS role_id,
    co.name AS company_name,
    mt.kind AS company_type,
    k.keyword AS movie_keyword
FROM 
    aka_title ak
JOIN 
    title t ON ak.movie_id = t.id
JOIN 
    cast_info c ON c.movie_id = t.id
JOIN 
    aka_name akn ON akn.person_id = c.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name co ON co.id = mc.company_id
JOIN 
    company_type mt ON mt.id = mc.company_type_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year, ak.name;
