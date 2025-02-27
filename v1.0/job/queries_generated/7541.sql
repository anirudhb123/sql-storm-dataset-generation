SELECT 
    a.name AS actor_name,
    t.title AS film_title,
    c.kind AS cast_type,
    m.info AS movie_info,
    r.role AS person_role,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year > 2000 
    AND a.name ILIKE '%Smith%'
ORDER BY 
    t.production_year DESC, a.name;
