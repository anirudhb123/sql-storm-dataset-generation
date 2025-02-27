SELECT 
    t.title, 
    a.name AS actor_name, 
    p.info AS person_info, 
    m.info AS movie_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year ASC, 
    a.name;
