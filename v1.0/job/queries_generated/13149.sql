SELECT 
    t.title AS movie_title,
    c.name AS actor_name,
    r.role AS actor_role,
    p.info AS person_info,
    m.info AS movie_info
FROM 
    title t
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    name n ON an.person_id = n.imdb_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    person_info p ON ci.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    t.title, 
    c.name;
