SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    n.name AS company_name
FROM 
    aka_title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name n ON mc.company_id = n.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.kind IN ('actor', 'actress')
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
