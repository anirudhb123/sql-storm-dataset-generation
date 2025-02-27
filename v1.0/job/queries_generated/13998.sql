SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    p.info AS person_info,
    c.name AS company_name
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    role_type AS r ON ci.role_id = r.id
JOIN 
    person_info AS p ON a.person_id = p.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
