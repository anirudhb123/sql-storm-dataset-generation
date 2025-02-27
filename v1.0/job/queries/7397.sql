SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS comp_cast_type,
    k.keyword AS movie_keyword,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year >= 2000
AND 
    c.kind IN ('Actor', 'Actress')
ORDER BY 
    t.production_year DESC, a.name;
