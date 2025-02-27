SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS company_type,
    k.keyword,
    y.production_year
FROM 
    title t
JOIN 
    aka_title a_t ON t.id = a_t.movie_id
JOIN 
    aka_name a ON a_t.id = a.id
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_info_idx y ON mi.id = y.id
WHERE 
    r.role = 'actor' 
    AND y.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office')
ORDER BY 
    y.production_year DESC;
