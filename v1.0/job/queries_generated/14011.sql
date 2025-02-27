SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.note AS cast_note,
    k.keyword AS movie_keyword,
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
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, a.name;
