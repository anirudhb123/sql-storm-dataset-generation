SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    p.info AS person_info
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
    comp_cast_type AS ct ON ci.person_role_id = ct.id
JOIN 
    person_info AS p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, a.name;
