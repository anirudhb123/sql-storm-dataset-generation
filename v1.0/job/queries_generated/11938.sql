SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS role_type,
    t.production_year,
    kc.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    ak.name;
