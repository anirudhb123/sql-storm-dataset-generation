SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    r.role AS role,
    c.note AS cast_note,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, a.name;
