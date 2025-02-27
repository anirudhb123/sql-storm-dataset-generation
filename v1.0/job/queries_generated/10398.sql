SELECT 
    a.name AS aka_name,
    t.title AS title,
    c.person_id,
    c.movie_id,
    r.role AS role,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_info m ON c.movie_id = m.movie_id
JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
