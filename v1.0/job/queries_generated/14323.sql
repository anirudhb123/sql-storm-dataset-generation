SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.role_id AS actor_role,
    m.year AS production_year,
    k.keyword AS movie_keyword
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
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Production Year')
ORDER BY 
    t.title, a.name;
