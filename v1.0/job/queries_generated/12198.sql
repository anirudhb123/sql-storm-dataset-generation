SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS actor_name,
    c.kind AS role_type,
    ti.production_year,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info ti ON t.id = ti.movie_id
WHERE 
    ti.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
    AND ti.info IS NOT NULL
ORDER BY 
    ti.production_year DESC;
