SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    m.info AS movie_info
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    company_name cn ON t.id = cn.imdb_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    comp_cast_type c ON ci.role_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
