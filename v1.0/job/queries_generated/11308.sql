SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS character_name,
    c.nr_order,
    m.production_year
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    char_name c ON ci.role_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    a.name ASC;
