SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role_name,
    c.note AS cast_note,
    m.production_year AS production_year,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info c ON at.movie_id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    a.name;
