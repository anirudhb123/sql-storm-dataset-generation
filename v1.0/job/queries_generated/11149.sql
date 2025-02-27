SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    k.keyword AS movie_keyword,
    ct.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
