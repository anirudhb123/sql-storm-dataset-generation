SELECT 
    t.title, 
    a.name AS actor_name, 
    r.role 
FROM 
    title AS t 
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id 
JOIN 
    company_name AS c ON mc.company_id = c.id 
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id 
JOIN 
    cast_info AS ci ON cc.subject_id = ci.person_id 
JOIN 
    aka_name AS a ON ci.person_id = a.person_id 
JOIN 
    role_type AS r ON ci.role_id = r.id 
WHERE 
    c.country_code = 'USA' 
    AND t.production_year BETWEEN 2000 AND 2020 
ORDER BY 
    t.production_year DESC;
