SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS company_type
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
