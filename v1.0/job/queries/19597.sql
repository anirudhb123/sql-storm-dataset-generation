SELECT 
    t.title,
    a.name AS actor_name,
    p.info AS actor_info,
    c.kind AS company_type
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    company_name cn ON cn.id = (SELECT company_id FROM movie_companies WHERE movie_id = t.id LIMIT 1)
JOIN 
    company_type c ON cn.id = c.id
JOIN 
    person_info p ON p.person_id = a.person_id
WHERE 
    t.production_year = 2023;
