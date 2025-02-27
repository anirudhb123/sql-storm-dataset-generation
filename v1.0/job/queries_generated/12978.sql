-- Performance Benchmarking SQL Query
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS character_role,
    mc.company_id AS company_id,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, t.title;
