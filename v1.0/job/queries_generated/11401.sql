SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    r.role AS actor_role,
    c.name AS company_name,
    k.keyword AS movie_keyword,
    m.info AS movie_info
FROM 
    title t
JOIN 
    aka_title ak_t ON t.id = ak_t.movie_id
JOIN 
    aka_name ak ON ak_t.id = ak.id
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    ak.name;
