SELECT 
    t.title AS movie_title,
    t.production_year,
    a.name AS actor_name,
    r.role AS actor_role,
    k.keyword AS movie_keyword,
    c.name AS company_name,
    info.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type info ON mi.info_type_id = info.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
