SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    ci.kind AS cast_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id
WHERE 
    a.name LIKE 'John%' 
    AND t.production_year > 2000 
    AND ci.kind = 'cast'
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    c.nr_order ASC;
