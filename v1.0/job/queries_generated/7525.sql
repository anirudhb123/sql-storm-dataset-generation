SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    p.info AS actor_info,
    m.info AS movie_info,
    kw.keyword AS keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    a.name LIKE 'John%'
    AND t.production_year BETWEEN 2000 AND 2020
    AND c.kind IN (SELECT kind FROM comp_cast_type WHERE id IN (1,2,3))
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
