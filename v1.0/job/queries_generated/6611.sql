SELECT 
    a.name AS actor_name, 
    at.title AS movie_title, 
    at.production_year, 
    c.kind AS company_type, 
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    at.production_year >= 2000 
    AND c.kind LIKE '%Production%'
ORDER BY 
    at.production_year DESC, 
    a.name;
