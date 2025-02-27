SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    rt.role AS role,
    c.note AS cast_note,
    mk.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info c ON at.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
