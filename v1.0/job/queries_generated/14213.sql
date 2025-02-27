SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS cast_type,
    m.info AS movie_info
FROM 
    title AS t
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_info AS m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
